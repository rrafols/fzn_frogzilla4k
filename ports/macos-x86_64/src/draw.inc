; ===========================================================================
;  The city, the frog, and the helpers underneath them.
;
;  The arithmetic is the original's, still on the x87 unit; what changed is
;  that the Win32 code passed floats to OpenGL by pushing them, and here they
;  have to arrive in XMM registers, so every value the original left on the
;  stack for glTranslatef is now handed over through the FPOP slots.
;
;  Register use follows the original where it can: the loop counters that were
;  EBX/ESI/EDI/ECX live in R12-R15, which SysV preserves across a call the way
;  the Win32 API preserved theirs.  Each routine below pushes an odd number of
;  registers so that RSP stays 16-byte aligned at its own call sites.
; ===========================================================================

; ---------------------------------------------------------------------------
;  rand() in [-1,1), from Microsoft's LCG, taking the low sixteen bits signed.
;  Pushes the result onto the x87 stack.
; ---------------------------------------------------------------------------
section .text

myRandFloat:
    mov     eax, [holdrand]
    imul    eax, eax, 214013
    add     eax, 2531011
    mov     [holdrand], eax
    mov     [wTemp], ax
    fild    word [wTemp]
    fidiv   word [i32767]
    ret

; st0 = value, st1 = min, st2 = max  ->  st0 = clamped, the other two popped
clampminmaxz1:                          ; the same, with min 0 and max 1
    fldz
    fld1
    fxch    st2
clampminmax:
    fcomi   st0, st1
    fcmovb  st0, st1
    fcomi   st0, st2
    fcmovnb st0, st2
    fxch    st2
    fcompp
    ret

; ---------------------------------------------------------------------------
;  The unit cube, translated and scaled.  In the original this was three entry
;  points into one routine, reached by popping the return address around the
;  argument block; only drawCubeTS is ever called, so that is all there is here.
;
;  xmm0-2 = translation, xmm3-5 = scale.  The six values have to survive the
;  calls, so they go to the pool first.
; ---------------------------------------------------------------------------
cubeTS:
    push    r12
    push    r13
    push    r14
    movss   [ct0], xmm0
    movss   [ct1], xmm1
    movss   [ct2], xmm2
    movss   [cs0], xmm3
    movss   [cs1], xmm4
    movss   [cs2], xmm5
    CALLI   glPushMatrix
    movss   xmm0, [ct0]
    movss   xmm1, [ct1]
    movss   xmm2, [ct2]
    CALLI   glTranslatef
    movss   xmm0, [cs0]
    movss   xmm1, [cs1]
    movss   xmm2, [cs2]
    CALLI   glScalef

    mov     edi, GL_QUADS
    CALLI   glBegin
    lea     r12, [cubeverts]
    mov     r13d, 6
.face:
    movss   xmm0, [r12]
    movss   xmm1, [r12+4]
    movss   xmm2, [r12+8]
    CALLI   glNormal3f
    add     r12, 12
    mov     r14d, 4
.vert:
    movss   xmm0, [r12]
    movss   xmm1, [r12+4]
    movss   xmm2, [r12+8]
    CALLI   glVertex3f
    add     r12, 12
    dec     r14d
    jnz     .vert
    dec     r13d
    jnz     .face
    CALLI   glEnd
    CALLI   glPopMatrix
    pop     r14
    pop     r13
    pop     r12
    ret

; A shorthand for the call above, since every solid in the city is one of these.
%macro CUBE 6
    movss   xmm0, [%1]
    movss   xmm1, [%2]
    movss   xmm2, [%3]
    movss   xmm3, [%4]
    movss   xmm4, [%5]
    movss   xmm5, [%6]
    call    cubeTS
%endmacro
%macro CUBE0 3                          ; the same, with no translation
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    xorps   xmm2, xmm2
    movss   xmm3, [%1]
    movss   xmm4, [%2]
    movss   xmm5, [%3]
    call    cubeTS
%endmacro

; ---------------------------------------------------------------------------
;  Freddy: nine GLU spheres.  The original never pushed the matrix between
;  them, so each translation is relative to the one before - that is how the
;  frog is put together, and it is kept.
; ---------------------------------------------------------------------------
drawFrog:
    push    r12
    xor     r12d, r12d
.sphere:
    lea     rax, [ranapx]
    movss   xmm0, [rax + r12*4]
    lea     rax, [ranapy]
    movss   xmm1, [rax + r12*4]
    lea     rax, [ranapz]
    movss   xmm2, [rax + r12*4]
    CALLI   glTranslatef
    lea     rax, [ranarc]
    movzx   eax, byte [rax + r12]
    shl     eax, 2
    lea     rdi, [Colors]
    add     rdi, rax
    CALLI   glColor4ubv
    lea     rax, [ranarad]
    cvtss2sd xmm0, dword [rax + r12*4]
    mov     rdi, [quadric]
    mov     esi, 20
    mov     edx, 20
    CALLI   gluSphere
    inc     r12d
    cmp     r12d, 9
    jne     .sphere
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  A street lamp: a grey post with a white bulb on top.
; ---------------------------------------------------------------------------
drawFanal:
    push    r12
    lea     rdi, [fanal]
    CALLI   glColor4ubv
    CUBE    f0_0, f0_02, f0_0, f0_0012, f0_02, f0_0012
    lea     rdi, [onev]
    CALLI   glColor4ubv
    CUBE    f0_0, f0_04, f0_0, f0_003, f0_003, f0_003
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  One city block: a pavement, four sets of three lamps around it, and a
;  tower of "height" floors.  As the destruction front passes, the lamps tip
;  over and the floors rotate off their footings.
;
;  Reads destruct and height, both set by drawMultiBlock.
; ---------------------------------------------------------------------------
drawBlock:
    push    r12
    push    r13
    push    r14
    lea     rdi, [colorBlock]
    CALLI   glColor4ubv
    CUBE0   f0_0715, f0_002, f0_065

    fild    word [i30]                  ; the lamps' lean: clamp((d-h)*8, 0, 30)
    fldz
    fld     dword [destruct]
    fisub   dword [height]
    fimul   word [i8]
    call    clampminmax
    fstp    dword [tmpd2]

    xor     r12d, r12d
.side:
    movss   xmm0, [f90_0]
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    CALLI   glPushMatrix
    movss   xmm0, [f0_03]
    xorps   xmm1, xmm1
    movss   xmm2, [f0_06]
    CALLI   glTranslatef
    xor     r13d, r13d
.lamp:
    movss   xmm0, [tmpd2]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    call    drawFanal
    movss   xmm0, [fm0_03]              ; the lean and the step both accumulate,
    xorps   xmm1, xmm1                  ; exactly as in the original
    xorps   xmm2, xmm2
    CALLI   glTranslatef
    inc     r13d
    cmp     r13d, 2
    jle     .lamp
    CALLI   glPopMatrix
    inc     r12d
    cmp     r12d, 4
    jne     .side

    xor     r12d, r12d
.floor:
    CALLI   glPushMatrix
    fild    word [i67]                  ; this floor's collapse angle
    fldz
    mov     [wTemp], r12d
    fld     dword [destruct]
    fiadd   dword [wTemp]
    fisub   dword [height]
    fimul   word [i18]
    call    clampminmax
    fstp    dword [tmpd2]

    imul    eax, r12d, 90
    mov     [wTemp], eax
    fild    dword [wTemp]
    FPOP    0
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    movss   xmm0, [tmpd2]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    mov     [wTemp], r12d
    fild    dword [wTemp]
    fmul    dword [f0_05]
    fadd    dword [f0_02]
    FPOP    1
    xorps   xmm0, xmm0
    xorps   xmm2, xmm2
    CALLI   glTranslatef

    lea     rdi, [edifCol]
    CALLI   glColor4ubv
    CUBE0   f0_055, f0_02, f0_055
    lea     rdi, [edifCol + 4]
    CALLI   glColor4ubv
    CUBE    f0_0, f0_02, f0_0, f0_05, f0_01, f0_05

    xor     r13d, r13d                  ; the windows, five to a face
.wallface:
    movss   xmm0, [f90_0]
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    xor     r14d, r14d
.window:
    lea     rdi, [zerov]                ; lit only if the noise says so and
    call    myRandFloat                 ; this floor has not started to fall
    fldz
    fcomip  st1
    jnc     .dark
    fstp    st0
    fld     dword [tmpd2]
    fldz
    fcomip  st1
    jc      .dark
    lea     rdi, [onev]
.dark:
    fstp    st0
    CALLI   glColor4ubv
    lea     eax, [r14 - 2]
    mov     [wTemp], eax
    fild    dword [wTemp]
    fmul    dword [f0_018]
    FPOP    2
    movss   xmm0, [f0_055]
    xorps   xmm1, xmm1
    movss   xmm3, [f0_001]
    movss   xmm4, [f0_007]
    movss   xmm5, [f0_007]
    call    cubeTS
    inc     r14d
    cmp     r14d, 4
    jle     .window
    inc     r13d
    cmp     r13d, 4
    jl      .wallface

    CALLI   glPopMatrix
    inc     r12d
    cmp     r12d, [height]
    jne     .floor

    pop     r14
    pop     r13
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  The city: a ground plane and a 9x9 grid of blocks.  Each block's height
;  comes out of the same PRNG the whole frame shares, so the skyline is stable
;  from frame to frame; only the middle three columns are ever demolished.
; ---------------------------------------------------------------------------
drawMultiBlock:
    push    r12
    push    r14
    push    r15
    CUBE    f0_0, fm0_008, f0_0, f2_0, f0_004, f1_2

    xor     r14d, r14d
.ni:
    xor     r15d, r15d
.nj:
    CALLI   glPushMatrix
    mov     eax, r14d
    sub     eax, CITY_HEIGHT / 2
    mov     [wTemp], eax
    fild    dword [wTemp]
    fmul    dword [f0_24]
    FPOP    0
    mov     eax, r15d
    sub     eax, CITY_WIDTH / 2
    mov     [wTemp], eax
    fild    dword [wTemp]
    fmul    dword [f0_24]
    FPOP    2
    xorps   xmm1, xmm1
    CALLI   glTranslatef

    fld     dword [v_ts]                ; the destruction front, per row
    fisub   word [i3100]
    fmul    dword [f0_05]
    imul    eax, r14d, 5
    mov     [wTemp], eax
    fild    dword [wTemp]
    fiadd   word [i11]
    fsubp   st1, st0
    fstp    dword [destruct]

    mov     eax, r15d                   ; ... but only in the middle columns
    sub     eax, CITY_WIDTH / 2
    cdq
    xor     eax, edx
    sub     eax, edx
    and     al, 254
    jz      .doDestruct
    mov     dword [destruct], 0
.doDestruct:
    call    myRandFloat
    fabs
    fimul   word [i7]
    fld1
    faddp   st1, st0
    fistp   dword [height]
    call    drawBlock
    CALLI   glPopMatrix

    inc     r15d
    cmp     r15d, CITY_WIDTH
    jl      .nj
    inc     r14d
    cmp     r14d, CITY_HEIGHT
    jl      .ni
    pop     r15
    pop     r14
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  One car.  edi selects its colour.
; ---------------------------------------------------------------------------
drawVehicle:
    push    r12
    and     edi, 7
    shl     edi, 2
    lea     rax, [carColors]
    add     rdi, rax
    CALLI   glColor4ubv
    CUBE0   f0_0061, f0_0025, f0_01
    CUBE    f0_0, f0_0057, fm0_002, f0_0061, f0_0003, f0_004
    movss   xmm0, [fm28_65]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    CUBE    f0_0, fm0_0048, f0_0088, f0_0061, f0_0022, f0_0012
    lea     rdi, [clGlass]
    CALLI   glColor4ubv
    movss   xmm0, [fm22_92]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    CUBE    f0_0, fm0_0006, f0_0025, f0_006, f0_0024, f0_003
    movss   xmm0, [f51_57]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    xorps   xmm3, xmm3
    CALLI   glRotatef
    CUBE    f0_0, f0_004, fm0_002, f0_006, f0_0015, f0_004
    lea     rdi, [onev]                 ; the headlights
    CALLI   glColor4ubv
    CUBE    f0_003, f0_0, f0_01, f0_0015, f0_0015, f0_0015
    CUBE    fm0_003, f0_0, f0_01, f0_0015, f0_0015, f0_0015
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  The traffic.  Every intersection seeds the PRNG from its own coordinates
;  and the current lap, which is what makes the cars appear in the same places
;  every run, and slide along as dtime0 advances.
; ---------------------------------------------------------------------------
drawMultiVehicle:
    push    r12
    push    r13
    push    r14
    push    r15
    push    r15
    xor     r14d, r14d                  ; xcpos
.nj:
    xor     r15d, r15d                  ; zcpos
.ni:
    fld     dword [dtime0]
    fadd    st0, st0
    mov     [wTemp], r15d
    fiadd   dword [wTemp]
    mov     [wTemp], r14d
    fiadd   dword [wTemp]
    fistp   dword [holdrand]
    call    myRandFloat
    fabs
    fadd    st0, st0
    fadd    st0, st0
    fistp   dword [ncars]
    dec     dword [ncars]

    xor     r13d, r13d                  ; cedge
.cedge:
    movss   xmm0, [f90_0]
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef
    xor     r12d, r12d                  ; cepos
.cepos:
    CALLI   glPushMatrix
    mov     eax, r12d
    shl     eax, 2
    add     eax, r13d
    cdqe
    fld     dword [caroffsets + rax*4]
    fadd    st0, st0
    mov     eax, r15d
    sub     eax, (CITY_WIDTH + CANTONADES) / 2 - 1
    mov     [wTemp], eax
    fild    dword [wTemp]
    fsubp   st1, st0
    fmul    dword [f0_24]
    fld1
    mov     [wTemp], r12d
    fisub   dword [wTemp]
    fmul    dword [f0_05]
    faddp   st1, st0
    FPOP    2
    mov     eax, r14d
    sub     eax, (CITY_HEIGHT + CANTONADES) / 2 - 1
    mov     [wTemp], eax
    fild    dword [wTemp]
    fmul    dword [f0_24]
    fsubr   dword [f0_1]
    FPOP    0
    xorps   xmm1, xmm1
    CALLI   glTranslatef

    call    myRandFloat                 ; the crash spin, once Freddy lands
    fmul    dword [carrotate]
    FPOP    0
    xorps   xmm1, xmm1
    movss   xmm2, [f1_0]
    xorps   xmm3, xmm3
    CALLI   glRotatef

    call    myRandFloat
    fabs
    fimul   word [i7]
    fistp   dword [wTemp]
    mov     edi, [wTemp]
    call    drawVehicle
    CALLI   glPopMatrix

    inc     r12d
    cmp     r12d, [ncars]
    jl      .cepos
    inc     r13d
    cmp     r13d, 4
    jl      .cedge
    inc     r15d
    cmp     r15d, CITY_WIDTH + CANTONADES
    jl      .ni
    inc     r14d
    cmp     r14d, CITY_HEIGHT
    jl      .nj
    pop     r15
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  timeCalc: where Freddy is, how far the traffic has travelled, and how hard
;  the cars are spinning - all derived from ts alone.
;
;  Two things about the original are worth writing down.  The test that was
;  meant to skip the destruction before ts 3100 is a "jl" after an FCOMIP,
;  which clears SF and OF, so it never branches: the destruction arithmetic
;  always runs.  Before ts 3100 it puts Freddy far off in the distance, where
;  no camera is looking, so it does not show.  And the branch it never takes
;  is the one that would have popped the value below FreddyPos, so the
;  original leaks one x87 register per frame.  That is harmless - the stack
;  wraps and the stale slot is retaken before it is read - but there is no
;  reason to reproduce it, so it is popped here.
; ---------------------------------------------------------------------------
timeCalc:
    mov     dword [FreddyPos], 0
    mov     eax, 0x447a0000             ; 1000.0f
    mov     [FreddyAlt], eax

    fld     dword [v_ts]
    fisub   word [i3100]
    fidiv   word [i100]
    fstp    dword [delta]

    fld     dword [delta]               ; a hop per unit of delta ...
    fsub    dword [f0_5]
    fist    dword [wTemp]
    fild    dword [wTemp]
    fld     st0
    fsubr   dword [delta]
    fadd    st0, st0
    call    clampminmaxz1
    faddp   st1, st0
    fisub   word [i8]
    fmul    dword [f0_24]
    fstp    dword [FreddyPos]
    fstp    st0                         ; the slot the original leaks

    fild    word [i1000]                ; ... and the arc of each hop
    fldz
    fld     dword [delta]
    fadd    st0, st0
    fldpi
    fmulp   st1, st0
    fsin
    fmul    dword [f0_4]
    call    clampminmax
    fstp    dword [FreddyAlt]

    fild    word [i30]
    fldz
    fld     dword [v_ts]
    fisub   word [i2850]
    fiadd   word [i20]
    fmul    dword [f1_5]
    call    clampminmax
    fstp    dword [carrotate]

    fild    word [i2850]                ; the traffic freezes at ts 2850
    fldz
    fld     dword [v_ts]
    call    clampminmax
    fstp    dword [doffset]

    fld     dword [doffset]
    fmul    dword [f0_0015]
    fld     st0
    fsub    dword [f0_5]
    fistp   dword [dtime0]              ; whole laps ...
    fild    dword [dtime0]
    fst     dword [dtime0]
    fsubp   st1, st0
    fstp    dword [dtime1]              ; ... and the fraction of this one

    push    r12
    push    r13
    push    r13
    xor     r12d, r12d                  ; toffset
    xor     r13d, r13d                  ; cepos
.cepos_loop:
    xor     ecx, ecx                    ; cedge
.cedge_loop:
    mov     [wTemp], r13d
    fild    dword [wTemp]
    fmul    dword [fcarfase]
    fsubr   dword [dtime1]
    mov     eax, ecx
    and     eax, 1
    jnz     .cedge_pair
    fsub    dword [f0_5]
.cedge_pair:
    fstp    dword [doffset]
    fld     dword [doffset]
    fdiv    dword [f0_4]
    call    clampminmaxz1
    fstp    dword [caroffsets + r12*4]
    inc     r12d
    inc     ecx
    cmp     ecx, 4
    jl      .cedge_loop
    inc     r13d
    cmp     r13d, CAR_NUM
    jl      .cepos_loop
    pop     r13
    pop     r13
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  The glow: the 256x256 render-to-texture from pass three, drawn back over
;  the frame six times additively at successively coarser mip levels.  It is
;  the whole look of the intro - everything bright bleeds.
; ---------------------------------------------------------------------------
drawGlow:
    push    r12
    CALLI   glLoadIdentity
    movss   xmm0, [fm0_665]
    movss   xmm1, [fm0_5]
    movss   xmm2, [fm1_2]
    CALLI   glTranslatef
    mov     edi, GL_TEXTURE_2D
    CALLI   glEnable
    mov     edi, GL_BLEND
    CALLI   glEnable
    mov     edi, GL_SRC_ALPHA
    mov     esi, GL_ONE
    CALLI   glBlendFunc
    xor     r12d, r12d
.glowin:
    lea     eax, [r12 + 1]
    mov     [wTemp], eax
    fild    dword [wTemp]
    FPOP    0
    mov     edi, GL_TEXTURE_FILTER_CONTROL
    mov     esi, GL_TEXTURE_LOD_BIAS
    CALLI   glTexEnvf
    call    drawQuad
    inc     r12d
    cmp     r12d, 6
    jl      .glowin
    mov     edi, GL_TEXTURE_2D
    CALLI   glDisable
    mov     edi, GL_BLEND
    CALLI   glDisable
    pop     r12
    ret

; The 4:3 quad the glow is drawn on, with its origin at the bottom left.
drawQuad:
    push    r12
    mov     edi, GL_QUADS
    CALLI   glBegin
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    CALLI   glTexCoord2f
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    movss   xmm0, [f1_0]
    xorps   xmm1, xmm1
    CALLI   glTexCoord2f
    movss   xmm0, [f1_333]
    xorps   xmm1, xmm1
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    movss   xmm0, [f1_0]
    movss   xmm1, [f1_0]
    CALLI   glTexCoord2f
    movss   xmm0, [f1_333]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    xorps   xmm0, xmm0
    movss   xmm1, [f1_0]
    CALLI   glTexCoord2f
    xorps   xmm0, xmm0
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    CALLI   glEnd
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  The credits.  edi = first string, esi = how many; the strings themselves
;  are ranges of "textos", drawn through the glyph display lists built by
;  init_text.
; ---------------------------------------------------------------------------
drawText:
    push    r12
    push    r13
    push    r13
    mov     r12d, edi
    mov     r13d, esi
    mov     edi, GL_DEPTH_TEST
    CALLI   glDisable
.drawinText:
    CALLI   glPushMatrix
    lea     rax, [texxpos]
    movss   xmm0, [rax + r12*4]
    lea     rax, [texypos]
    movss   xmm1, [rax + r12*4]
    lea     rax, [texsize]
    movss   xmm2, [rax + r12*4]
    CALLI   glTranslatef
    lea     rax, [textoffset]
    movzx   ecx, byte [rax + r12]
    movzx   edx, byte [rax + r12 + 1]
    sub     edx, ecx
    lea     rsi, [textos]
    add     rsi, rcx
    mov     edi, edx
    mov     rdx, rsi
    mov     esi, GL_UNSIGNED_BYTE
    CALLI   glCallLists
    CALLI   glPopMatrix
    inc     r12d
    dec     r13d
    jnz     .drawinText
    pop     r13
    pop     r13
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  Getting the 640x480 frame onto a modern display.
;
;  The original forced a 640x480 mode and hard-coded 4:3.  A Mac keeps its own
;  resolution, so the intro renders into the corner of the back buffer at the
;  size it was made for and that corner is blitted, letterboxed, to the
;  drawable.  Doing it this way rather than just widening the viewport also
;  keeps the 256x256 glow source the same fraction of the picture it was.
; ---------------------------------------------------------------------------
make_tex:
    push    r12
    mov     edi, 1
    lea     rsi, [scenetex]
    CALLI   glGenTextures
    mov     edi, GL_TEXTURE_2D
    mov     esi, [scenetex]
    CALLI   glBindTexture
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_MIN_FILTER
    mov     edx, GL_LINEAR
    CALLI   glTexParameteri
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_MAG_FILTER
    mov     edx, GL_LINEAR
    CALLI   glTexParameteri
    ; The blit quad's texture coordinates run exactly 0..1, so a GL_LINEAR tap
    ; at the border sits half a texel outside the image - and under the default
    ; GL_REPEAT that half comes from the opposite edge.  With the credits
    ; running off the right of the screen, its glow reappeared as a bright line
    ; down the left border.
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_WRAP_S
    mov     edx, GL_CLAMP_TO_EDGE
    CALLI   glTexParameteri
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_WRAP_T
    mov     edx, GL_CLAMP_TO_EDGE
    CALLI   glTexParameteri
    mov     edi, GL_TEXTURE_2D          ; the glow lives in texture object 0
    xor     esi, esi
    CALLI   glBindTexture
    pop     r12
    ret

bind_fbo:
    push    r12
    xor     edi, edi
    xor     esi, esi
    mov     edx, RENDER_W
    mov     ecx, RENDER_H
    CALLI   glViewport
    pop     r12
    ret

blit_frame:
    push    r12
    mov     edi, GL_TEXTURE_2D
    mov     esi, [scenetex]
    CALLI   glBindTexture
    sub     rsp, 16                     ; glCopyTexImage2D's last two arguments
    mov     qword [rsp], RENDER_H
    mov     qword [rsp+8], 0
    mov     edi, GL_TEXTURE_2D
    xor     esi, esi
    mov     edx, GL_RGBA
    xor     ecx, ecx
    xor     r8d, r8d
    mov     r9d, RENDER_W
    CALLI   glCopyTexImage2D
    add     rsp, 16

    xor     edi, edi                    ; wipe the whole drawable, so the
    xor     esi, esi                    ; corner just rendered does not show
    mov     edx, [vpbuf+8]              ; through the letterbox bars
    mov     ecx, [vpbuf+12]
    CALLI   glViewport
    mov     edi, GL_COLOR_BUFFER_BIT
    CALLI   glClear
    mov     edi, [blitx]
    mov     esi, [blity]
    mov     edx, [blitw]
    mov     ecx, [blith]
    CALLI   glViewport

    mov     edi, GL_DEPTH_TEST
    CALLI   glDisable
    mov     edi, GL_LIGHTING
    CALLI   glDisable
    mov     edi, GL_BLEND
    CALLI   glDisable
    mov     edi, GL_TEXTURE_2D
    CALLI   glEnable
    mov     edi, GL_PROJECTION
    CALLI   glMatrixMode
    CALLI   glLoadIdentity
    mov     edi, GL_MODELVIEW
    CALLI   glMatrixMode
    CALLI   glLoadIdentity
    movss   xmm0, [f1_0]
    movss   xmm1, [f1_0]
    movss   xmm2, [f1_0]
    CALLI   glColor3f
    mov     edi, GL_QUADS
    CALLI   glBegin
    xorps   xmm0, xmm0
    xorps   xmm1, xmm1
    CALLI   glTexCoord2f
    movss   xmm0, [fm1_0]
    movss   xmm1, [fm1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    movss   xmm0, [f1_0]
    xorps   xmm1, xmm1
    CALLI   glTexCoord2f
    movss   xmm0, [f1_0]
    movss   xmm1, [fm1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    movss   xmm0, [f1_0]
    movss   xmm1, [f1_0]
    CALLI   glTexCoord2f
    movss   xmm0, [f1_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    xorps   xmm0, xmm0
    movss   xmm1, [f1_0]
    CALLI   glTexCoord2f
    movss   xmm0, [fm1_0]
    movss   xmm1, [f1_0]
    xorps   xmm2, xmm2
    CALLI   glVertex3f
    CALLI   glEnd

    mov     edi, GL_TEXTURE_2D          ; hand texture 0 back to the glow
    xor     esi, esi
    CALLI   glBindTexture
    mov     edi, GL_TEXTURE_2D
    CALLI   glDisable
    pop     r12
    ret
