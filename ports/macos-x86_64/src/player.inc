; ---------------------------------------------------------------------------
;  Module playback.
;
;  The original handed eight DirectSound secondary buffers to the mixer and
;  drove them from a thread that woke every 160 ms, calling SetFrequency,
;  SetVolume, SetCurrentPosition and Play on them.  CoreAudio has no per-buffer
;  pitch or volume, so that mixing is explicit here: the whole tune is rendered
;  once into a single AudioQueue buffer before the intro starts, which also
;  removes the player thread - visuals and music now come off one clock.
;
;  The original could be built for two DirectSound formats, 44100 mono (the
;  "XP" build) and 22050 stereo (the "2K" one); the same eight-bit stream is
;  fed to both, and reading it as interleaved stereo is why the .nfo says it
;  sounds worse on 2000.  This is the 44100 mono behaviour.
;
;  A channel record in zik.asm is 25 bytes: one instrument byte, twelve note
;  bytes, twelve effect bytes.  A note byte is  note | octave<<4 | volume<<6,
;  with note 0 meaning "nothing here", 15 meaning note cut, and effect byte 1
;  meaning tone portamento - keep playing, just change the pitch.
;
;  A voice is 16 bytes: instrument (-1 = idle), position in bytes, step, gain.
; ---------------------------------------------------------------------------

; in: rdi = 16-bit PCM destination (TOTAL_SAMPLES entries)
section .text

rendersong:
    push    r12
    push    r13
    push    r14
    push    r15

    lea     rsi, [voices]               ; all voices idle
    mov     ecx, NCHANNELS
.silence:
    mov     dword [rsi], -1
    mov     dword [rsi+4], 0
    mov     dword [rsi+8], 0
    mov     dword [rsi+12], 0
    add     rsi, 16
    dec     ecx
    jnz     .silence

    xor     r12d, r12d                  ; order
.order:
    lea     rax, [orderList]
    movzx   eax, byte [rax + r12]
    shl     eax, 3                      ; eight channels per pattern
    mov     r13d, eax
    xor     r14d, r14d                  ; row
.row:
    xor     ecx, ecx                    ; channel
.chan:
    lea     rsi, [patternList]
    add     rsi, r13
    movsx   eax, byte [rsi + rcx]
    test    eax, eax
    js      .nextchan                   ; 255 = channel unused in this pattern

    lea     rsi, [channelList]
    imul    eax, eax, 25                ; instrument + 12 notes + 12 effects
    add     rsi, rax
    movzx   r8d, byte [rsi]             ; instrument
    add     rsi, r14
    movzx   eax, byte [rsi + 1]         ; note byte for this row
    test    eax, eax
    jz      .nextchan
    movzx   r11d, byte [rsi + 13]       ; effect byte for this row

    mov     r9, rcx                     ; -> voice
    shl     r9, 4
    lea     r10, [voices]
    add     r9, r10

    mov     edx, eax
    and     edx, 15
    dec     edx                         ; -1 = volume only, 14 = note cut
    mov     r10d, eax
    shr     r10d, 6
    and     r10d, 3
    lea     rsi, [volgain]
    mov     r10d, [rsi + r10*4]         ; gain for this note's volume column

    cmp     edx, 14
    je      .cut
    cmp     edx, -1
    je      .volonly

    shr     eax, 4                      ; octave
    and     eax, 3
    add     eax, 3                      ; the module's base octave
    imul    eax, eax, 12
    add     eax, edx
    lea     rsi, [freqtable]
    cvtsi2ss xmm0, dword [rsi + rax*4]
    divss   xmm0, [rate_f]
    movss   [r9+8], xmm0                ; step, in sample bytes per output frame
    mov     [r9], r8d
    mov     [r9+12], r10d
    cmp     r11d, 1
    je      .nextchan                   ; tone portamento: keep the position
    mov     dword [r9+4], 0
    jmp     .nextchan
.volonly:
    mov     [r9+12], r10d
    jmp     .nextchan
.cut:
    mov     dword [r9], -1
    mov     dword [r9+4], 0
    mov     dword [r9+12], 0
.nextchan:
    inc     ecx
    cmp     ecx, NCHANNELS
    jne     .chan

    ; ---- mix this row -----------------------------------------------------
    mov     r15d, ROW_SAMPLES
.sample:
    xorps   xmm7, xmm7
    lea     r9, [voices]
    mov     ecx, NCHANNELS
.mix:
    mov     eax, [r9]
    test    eax, eax
    js      .nextvoice
    cvttss2si edx, dword [r9+4]
    imul    r10d, eax, 16
    lea     r11, [samples]
    movzx   r11d, word [r11 + r10 + 1]  ; nSamples ...
    shl     r11d, 4                     ; ... times sixteen is the byte count
    cmp     edx, r11d
    jl      .inrange
    mov     dword [r9], -1              ; one-shot finished
    jmp     .nextvoice
.inrange:
    imul    r10, rax, SAMP_STRIDE
    lea     r11, [sampbuf]
    add     r11, r10
    movzx   r10d, byte [r11 + rdx]
    sub     r10d, 127                   ; the generator centres on 127
    cvtsi2ss xmm0, r10d
    mulss   xmm0, [r9+12]
    addss   xmm7, xmm0
    movss   xmm0, [r9+8]
    addss   xmm0, [r9+4]
    movss   [r9+4], xmm0
.nextvoice:
    add     r9, 16
    dec     ecx
    jnz     .mix

    mulss   xmm7, [mastergain]
    cvtps2dq xmm7, xmm7                 ; the upper lanes stay zero
    packssdw xmm7, xmm7                 ; saturating -> 16 bit
    movd    eax, xmm7
    mov     [rdi], ax
    add     rdi, 2
    dec     r15d
    jnz     .sample

    inc     r14d
    cmp     r14d, ROWS
    jne     .row
    inc     r12d
    cmp     r12d, ORDERS
    jne     .order

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret
