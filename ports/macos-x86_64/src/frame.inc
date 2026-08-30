; ===========================================================================
;  Per-frame code.
;
;  The original ran the visuals off GetTickCount divided by a "timeDivider"
;  that the player thread kept adjusting so that ts tracked the module's row
;  counter: twelve rows (one order) advanced ts by 99.  With the tune now
;  mixed up front there is no thread to measure anything, so ts comes straight
;  off the clock at the rate that feedback loop was converging on -
;  8.25 ticks per 166.667 ms row, or 0.0495 per millisecond.
;
;  Each frame draws the scene three times, exactly as the original did:
;
;      pass 3   at 256x256, in bright colours, read back as the glow texture
;      pass 2   at full size, then the glow blended over it
;      pass 1   the scene once more, in black, cutting the glow back out
;
;  which is why the text is drawn in its own colour only on the first pass and
;  in black afterwards: what you see is the halo, with a silhouette in it.
; ===========================================================================

_frame:
    call    bind_fbo                    ; render at the size the original forced
    call    get_ms
    mov     [wTemp], eax
    fild    dword [wTemp]
    fmul    dword [ts_scale]
    fstp    dword [v_ts]

%if OFFSCREEN == 0
    mov     edi, kCGEventSourceStateHIDSystemState
    mov     esi, KEY_ESC
    CALLI   CGEventSourceKeyState
    test    al, al
    jnz     exitIntro
%endif

    mov     edi, GL_TEXTURE_2D          ; the glow texture wants its mip chain
    mov     esi, GL_TEXTURE_MIN_FILTER  ; rebuilt from every upload
    mov     edx, GL_LINEAR_MIPMAP_LINEAR
    CALLI   glTexParameteri
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_GENERATE_MIPMAP
    mov     edx, 1
    CALLI   glTexParameteri

    mov     edi, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
    CALLI   glClear
    mov     edi, GL_PROJECTION
    CALLI   glMatrixMode
    CALLI   glLoadIdentity
    movsd   xmm0, [d_fovy]
    movsd   xmm1, [d_aspect]
    movsd   xmm2, [d_znear]
    movsd   xmm3, [d_zfar]
    CALLI   gluPerspective
    mov     edi, GL_MODELVIEW
    CALLI   glMatrixMode
    CALLI   glLoadIdentity

; ---------------------------------------------------------------------------
;  Camera.  dacamera is still last frame's - the original set it further down,
;  after the camera had already been placed, and one frame of lag is invisible.
; ---------------------------------------------------------------------------
    mov     eax, [dacamera]
    cmp     eax, 20
    jl      .novibra
    fld     dword [v_ts]                ; a sin(x)/x shudder, from camera 20 on
    fisub   word [i800]
    fild    dword [dacamera]
    fimul   word [i100]
    fsubp   st1, st0
    fld     st0
    fsin
    fdivrp  st1, st0
    fidiv   word [i100]
    FPOP    1
    xorps   xmm0, xmm0
    xorps   xmm2, xmm2
    CALLI   glTranslatef
.novibra:
    mov     eax, [dacamera]
    test    eax, eax
    js      .endCamera                  ; before ts 800 the text needs no camera
    cmp     eax, 45
    jge     exitIntro
    cmp     eax, 36
    jge     .endCamera
    lea     rcx, [camera_table]
    movzx   eax, byte [rcx + rax]
    cmp     eax, 1
    je      .camera1
    cmp     eax, 2
    je      .camera2
    cmp     eax, 3
    je      .camera3
    cmp     eax, 4
    je      .camera4
    cmp     eax, 5
    je      .camera5

.camera0:                               ; sliding down onto the city
    fld     dword [v_ts]
    fmul    dword [f0_001]
    fld     dword [f1_5]
    fsubrp  st1, st0
    FPOP    1
    xorps   xmm0, xmm0
    movss   xmm2, [fm1_0]
    CALLI   glTranslatef
    movss   xmm0, [f90_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    jmp     .endCamera

.camera1:                               ; orbit, 50 degrees down
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    movss   xmm2, [fm1_11]
    CALLI   glTranslatef
    movss   xmm0, [f50_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    fld     dword [v_ts]
    fmul    dword [f0_3]
    FPOP    0
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    jmp     .endCamera

.camera2:                               ; slower orbit, further out
    xorps   xmm0, xmm0
    movss   xmm1, [f0_3]
    movss   xmm2, [fm1_85]
    CALLI   glTranslatef
    fld     dword [v_ts]
    fidiv   word [i70]
    FPOP    0
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    movss   xmm0, [f40_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    jmp     .endCamera

.camera3:                               ; in among the buildings
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    movss   xmm2, [fm0_37]
    CALLI   glTranslatef
    movss   xmm0, [f30_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    fld     dword [v_ts]
    fmul    dword [f0_3]
    FPOP    0
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    jmp     .endCamera

.camera4:                               ; street level, riding with the traffic
    movss   xmm0, [f25_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    fld     dword [caroffsets + 4]
    fadd    dword [dtime0]
    fadd    st0, st0
    fmul    dword [f0_24]
    fsubr   dword [f1_5]
    FPOP    2
    movss   xmm0, [f0_84]
    movss   xmm1, [fm0_1]
    CALLI   glTranslatef
    jmp     .endCamera

.camera5:                               ; locked to Freddy
    fld     dword [FreddyPos]
    fadd    dword [f1_2]
    fchs
    FPOP    2
    fld     dword [FreddyAlt]
    fadd    dword [f0_2]
    fchs
    FPOP    1
    xorps   xmm0, xmm0
    movss   xmm2, [fp2]
    CALLI   glTranslatef
    movss   xmm0, [f25_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    movss   xmm0, [fm90_0]
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef

.endCamera:
    xor     edi, edi                    ; pass three renders the glow source
    xor     esi, esi
    mov     edx, R2T_SIZE
    mov     ecx, R2T_SIZE
    CALLI   glViewport
    mov     edi, GL_NORMALIZE
    CALLI   glEnable
    mov     edi, GL_LIGHT0
    CALLI   glEnable
    mov     edi, GL_BLEND
    CALLI   glEnable
    mov     edi, GL_COLOR_MATERIAL
    CALLI   glEnable
    mov     edi, GL_SRC_ALPHA
    mov     esi, GL_ZERO
    CALLI   glBlendFunc

    mov     dword [holdrand], 2
    call    timeCalc

    fld     dword [v_ts]                ; 0 = titles, 1 = city, 2 = credits
    fist    dword [wTemp]
    mov     eax, [wTemp]
    xor     r14d, r14d
    cmp     eax, 800
    jl      .phasedone
    inc     r14d
    cmp     eax, 4300
    jl      .phasedone
    inc     r14d
.phasedone:
    fisub   word [i800]
    fidiv   word [i100]
    fistp   dword [dacamera]

    mov     r15d, 3
.DrawLoop:
    mov     dword [holdrand], 2
    lea     rdi, [zerov]
    CALLI   glColor4ubv
    CALLI   glPushMatrix
    cmp     r14d, 1
    je      .NoDrawText

; ---- the titles and the credits -------------------------------------------
    cmp     r15d, 3
    jne     .ColoredFont
    lea     rdi, [fontcolor]
    CALLI   glColor4ubv
.ColoredFont:
    fild    word [i4750]                ; the text flies in from the distance:
    fld     dword [v_ts]                ; z is |clamp(ts,4750) - k| * 0.2 - 445,
    fcomi   st0, st1                    ; with k jumping at ts 2600 so that the
    fcmovnb st0, st1                    ; credits come back for a second run
    fild    word [i2600]
    fcomi   st1
    jb      .noHack
    fisubr  word [i1165]
.noHack:
    fsubp   st1, st0
    fabs
    fmul    dword [f0_2]
    fisub   word [i445]
    FPOP    2
    fstp    st0                         ; the slot the original leaks

    mov     edi, GL_LIGHTING
    CALLI   glDisable
    mov     edi, GL_BLEND
    CALLI   glDisable
    CALLI   glLoadIdentity
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    movss   xmm2, [fp2]
    CALLI   glTranslatef

    fld     dword [v_ts]                ; how many credit lines are up yet
    fisub   word [i4700]
    fidiv   word [i100]
    fistp   dword [wTemp]
    mov     ecx, [wTemp]
    cmp     ecx, 0
    jge     .nomespetit
    xor     ecx, ecx
.nomespetit:
    cmp     ecx, 4
    jle     .nomesgran
    mov     ecx, 4
.nomesgran:
    inc     ecx
    mov     esi, ecx
    fld     dword [v_ts]                ; and which one they start from
    fidiv   word [i4200]
    fistp   dword [wTemp]
    mov     edi, [wTemp]
    call    drawText
    jmp     .DrawFinish

; ---- the city -------------------------------------------------------------
.NoDrawText:
    cmp     r15d, 1
    je      .DrawFinish
    mov     dword [holdrand], 14
    mov     edi, GL_DEPTH_TEST
    CALLI   glEnable
    call    drawMultiBlock
    call    drawMultiVehicle

    CALLI   glPushMatrix                ; animateFreddy
    fld     dword [FreddyAlt]
    fadd    dword [f0_4]
    FPOP    1
    movss   xmm0, [FreddyPos]
    xorps   xmm2, xmm2
    CALLI   glTranslatef
    call    drawFrog
    CALLI   glPopMatrix

    mov     edi, GL_LIGHTING
    CALLI   glEnable
    mov     edi, GL_BLEND
    CALLI   glDisable
    mov     edi, GL_DEPTH_TEST
    CALLI   glDisable

.DrawFinish:
    cmp     r15d, 3
    jne     .NoGetR2T
    ; Grab the glow source.  The original read this back as GL_RGBA, but its
    ; PIXELFORMATDESCRIPTOR asked for cAlphaBits 0, so the colour buffer had no
    ; alpha bitplanes and every texel came back with alpha 1.0 - the glow's
    ; GL_SRC_ALPHA blend was therefore plain addition.  A Mac drawable always
    ; has alpha, so reading RGBA here would hand back what the pass actually
    ; wrote, which under GL_SRC_ALPHA/GL_ZERO is alpha squared, and the blend
    ; would square it again: the text survives that but the lights, which are
    ; a few per cent of the picture, disappear.  Read RGB, and the sampled
    ; alpha is 1 as it was in 2004.
    lea     rax, [da_pixels]
    sub     rsp, 16
    mov     [rsp], rax
    xor     edi, edi
    xor     esi, esi
    mov     edx, R2T_SIZE
    mov     ecx, R2T_SIZE
    mov     r8d, GL_RGB
    mov     r9d, GL_UNSIGNED_BYTE
    CALLI   glReadPixels
    add     rsp, 16
    lea     rax, [da_pixels]            ; and upload it, mip chain and all
    sub     rsp, 32
    mov     qword [rsp], GL_RGB
    mov     qword [rsp+8], GL_UNSIGNED_BYTE
    mov     [rsp+16], rax
    mov     edi, GL_TEXTURE_2D
    xor     esi, esi
    mov     edx, GL_RGB
    mov     ecx, R2T_SIZE
    mov     r8d, R2T_SIZE
    xor     r9d, r9d
    CALLI   glTexImage2D
    add     rsp, 32
    call    bind_fbo
    mov     edi, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
    CALLI   glClear
    jmp     .NextDrawLoop
.NoGetR2T:
    cmp     r15d, 2
    jne     .NextDrawLoop
    lea     rdi, [onev]
    CALLI   glColor4ubv
    mov     edi, GL_LIGHTING
    CALLI   glDisable
    call    drawGlow
.NextDrawLoop:
    CALLI   glPopMatrix
    dec     r15d
    jnz     .DrawLoop

%if OFFSCREEN
    call    grab_frame
%elif WINDOWED
    call    blit_frame
    call    window_flush
%else
    call    blit_frame
    mov     rdi, [ctx]
    CALLI   CGLFlushDrawable
%endif
    jmp     _frame
