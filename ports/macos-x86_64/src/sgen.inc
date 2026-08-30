; ---------------------------------------------------------------------------
;  Instrument synthesis - a direct port of the original sgen_perxxor.asm.
;
;  Each of the eight instruments is an oscillator (saw, sine, or square) plus
;  white noise, run through a resonant low-pass whose cutoff and resonance
;  sweep over the length of the sample, written out as unsigned 8-bit at
;  44100 Hz.  The x87 code is unchanged; only the addressing moved to 64-bit,
;  and the original's stack-slot scratch became named pool slots.
;
;  One quirk is reproduced deliberately.  The parameter block is unpacked by
;  pushing six values onto the x87 stack and popping them in reverse, and the
;  two amplitude terms come off in the opposite order to the C the file
;  documents: "amp" ends up holding dAmp/100 and "damp" ampIni/(100*n).  The
;  envelope therefore starts at roughly -1 and climbs to 0 instead of starting
;  at +1 and falling - the same decay, phase-inverted.  This is what shipped,
;  and it is what the intro sounds like.
;
;  The parameter struct is sixteen bytes:
;      +0  wavetype (b)   +1  nSamples (w)  +3  freqIni (w)  +5  dFreq (w)
;      +7  ddFreq (w)     +9  ampIni (b)   +10  dAmp (b)    +11  cutIni (b)
;     +12  dCut (b)      +13  resIni (b)   +14  dRes (b)    +15  randGain (b)
; ---------------------------------------------------------------------------

; in: esi = instrument index (0..NSAMPLES-1)
section .text

gensample:
    push    r12
    lea     r8, [samples]
    imul    rax, rsi, 16
    add     r8, rax                     ; -> the parameter block
    lea     rdi, [sampbuf]
    imul    rax, rsi, SAMP_STRIDE
    add     rdi, rax

    finit
    movzx   eax, word [r8+1]            ; nSamples, in bytes
    shl     eax, 4
    mov     [sg_n], eax
    mov     r12d, eax

    fild    word [r8+3]                 ; fVal  = freqIni
    fstp    dword [sg_fVal]
    fild    word [r8+5]                 ; fdVal = 1 + dFreq/16M
    fmul    dword [f_inv16M]
    fld1
    faddp   st1, st0
    fstp    dword [sg_fdVal]

    ; Six parameters on, six off - in reverse, which is where the amp/damp
    ; swap above comes from.
    movsx   eax, byte [r8+12]           ; dCut
    mov     [wTemp], eax
    fild    dword [wTemp]
    movsx   eax, byte [r8+14]           ; dRes
    mov     [wTemp], eax
    fild    dword [wTemp]
    movsx   eax, byte [r8+13]           ; resIni
    mov     [wTemp], eax
    fild    dword [wTemp]
    movzx   eax, byte [r8+11]           ; cutIni, unsigned
    mov     [wTemp], eax
    fild    dword [wTemp]
    movsx   eax, byte [r8+9]            ; ampIni
    mov     [wTemp], eax
    fild    dword [wTemp]
    movsx   eax, byte [r8+10]           ; dAmp
    mov     [wTemp], eax
    fild    dword [wTemp]

    fidiv   word [i100]
    fstp    dword [sg_amp]              ; amp  = dAmp / 100
    fidiv   word [i100]
    fidiv   dword [sg_n]
    fstp    dword [sg_damp]             ; damp = ampIni / (100 * n)
    fmul    dword [f0_0019274]
    fstp    dword [sg_f]                ; f    = cutIni * 85/44100
    fidiv   word [i100]
    fstp    dword [sg_q]                ; q    = resIni / 100
    fidiv   word [i100]
    fidiv   dword [sg_n]
    fstp    dword [sg_dres]
    fmul    dword [f0_0019274]
    fidiv   dword [sg_n]
    fstp    dword [sg_dcut]

    fldz                                ; buf1
    fldz                                ; buf0  buf1
    fldz                                ; phase buf0  buf1
.loop:
    fadd    dword [sg_fVal]             ; phase += fVal
    fist    dword [wTemp]               ; wrap the ramp through a signed word
    fild    word [wTemp]
    fmul    dword [f2_65]               ; val = 2 * (phase & 0xffff) / 65536

    mov     al, [r8]                    ; wavetype
    test    al, al
    jz      .rawsaw
    fstp    st0                         ; sine instead
    fld     st0
    fmul    dword [f2pi44100]
    fsin
    cmp     al, 2
    jne     .rawsaw
    fld1                                ; and square, if asked for
    fldz
    fcomip  st2
    jc      .positive
    fchs
.positive:
    fxch    st1
    fstp    st0
.rawsaw:
    movzx   eax, byte [r8+15]           ; += randGain * rand() / 127
    mov     [wTemp], eax
    fild    dword [wTemp]
    call    myRandFloat
    fmulp   st1, st0
    fidiv   word [i127]
    faddp   st1, st0

    fld     dword [sg_q]                ; lfb = q + q/(1-f)
    fld1
    fsub    dword [sg_f]
    fdivp   st1, st0
    fadd    dword [sg_q]
    fstp    dword [sg_store]

    fsub    st0, st2                    ; buf0 += f * (val - buf0 + lfb*(buf0-buf1))
    fld     st2
    fsub    st0, st4
    fmul    dword [sg_store]
    faddp   st1, st0
    fmul    dword [sg_f]
    fadd    st0, st2
    fstp    st2

    fld     st1                         ; buf1 += f * (buf0 - buf1)
    fsub    st0, st3
    fmul    dword [sg_f]
    faddp   st3, st0
    fld     st2                         ; the output sample is buf1

    fld     dword [sg_f]                ; f += dcut
    fadd    dword [sg_dcut]
    fstp    dword [sg_f]
    fld     dword [sg_q]                ; q += dres
    fadd    dword [sg_dres]
    fstp    dword [sg_q]

    fmul    dword [sg_amp]              ; apply and advance the envelope
    fld     dword [sg_fVal]
    fmul    dword [sg_fdVal]
    fstp    dword [sg_fVal]
    fld     dword [sg_amp]
    fadd    dword [sg_damp]
    fstp    dword [sg_amp]

    fimul   word [i127]
    fistp   dword [wTemp]
    mov     eax, [wTemp]
    cmp     eax, 127
    jle     .okup
    mov     eax, 127
.okup:
    cmp     eax, -127
    jge     .okdown
    mov     eax, -127
.okdown:
    add     eax, 127
    stosb
    dec     r12d
    jnz     .loop

    finit                               ; leave the x87 stack empty for callers
    pop     r12
    ret
