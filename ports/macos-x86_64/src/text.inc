; ---------------------------------------------------------------------------
;  The credits text.
;
;  The original asked GDI for Arial Bold and handed the device context to
;  wglUseFontOutlinesA, which compiled display lists 1..255 - one per character
;  code - each holding the filled outline of that glyph at em size 1.0 followed
;  by a glTranslatef of its advance.  glCallLists then drew a string by walking
;  its bytes.
;
;  There is no such call on macOS, so the same lists are built here by hand:
;  CoreText supplies the glyph outline as a CGPath, CGPathApply walks it,
;  quadratic and cubic segments are flattened into line segments, and the GLU
;  tessellator turns the resulting contours into triangles.  The tessellator's
;  begin/vertex/end callbacks are glBegin, glVertex3dv and glEnd, so with a
;  glNewList open the triangles land straight in the list, exactly as WGL did.
;
;  Only the sixteen letters the credits use are built, under their own
;  character codes, so glCallLists in drawText is unchanged.
; ---------------------------------------------------------------------------

section .text

%define FLATTEN_STEPS 8

init_text:
    push    r12
    push    r13
    push    r13                         ; odd count, so calls stay 16-aligned

    xor     edi, edi                    ; the font, at em size 1.0
    lea     rsi, [s_fontname]
    mov     edx, kCFStringEncodingUTF8
    CALLI   CFStringCreateWithCString
    mov     rdi, rax
    movsd   xmm0, [d_one]
    xor     esi, esi
    CALLI   CTFontCreateWithName
    mov     [ctfont], rax

    CALLI   gluNewTess                  ; and the tessellator, wired to GL
    mov     [tess], rax
    mov     rdi, rax
    mov     esi, GLU_TESS_BEGIN
    mov     rdx, [rbx + O_glBegin]
    CALLI   gluTessCallback
    mov     rdi, [tess]
    mov     esi, GLU_TESS_VERTEX
    mov     rdx, [rbx + O_glVertex3dv]
    CALLI   gluTessCallback
    mov     rdi, [tess]
    mov     esi, GLU_TESS_END
    mov     rdx, [rbx + O_glEnd]
    CALLI   gluTessCallback
    mov     rdi, [tess]
    mov     esi, GLU_TESS_COMBINE
    lea     rdx, [tess_combine]
    CALLI   gluTessCallback
    ; TrueType puts counters the other way round from their outer contour, so
    ; the nonzero rule is what leaves the holes in O, R and so on.
    mov     rdi, [tess]
    mov     esi, GLU_TESS_WINDING_RULE
    movsd   xmm0, [d_nonzero]
    CALLI   gluTessProperty
    mov     rdi, [tess]
    xorpd   xmm0, xmm0
    xorpd   xmm1, xmm1
    movsd   xmm2, [d_one]
    CALLI   gluTessNormal

    lea     r13, [textos]               ; one list per character of the credits
    mov     r12d, 32
.glyph:
    movzx   eax, byte [r13]
    mov     [ctmp], ax                  ; a UniChar for CoreText
    mov     rdi, [ctfont]
    lea     rsi, [ctmp]
    lea     rdx, [ctmp+8]
    mov     ecx, 1
    CALLI   CTFontGetGlyphsForCharacters

    mov     rdi, [ctfont]               ; the advance ends the list
    xor     esi, esi                    ; kCTFontOrientationDefault
    lea     rdx, [ctmp+8]
    xor     ecx, ecx
    mov     r8d, 1
    CALLI   CTFontGetAdvancesForGlyphs
    cvtsd2ss xmm0, xmm0
    movss   [g_adv], xmm0

    mov     rdi, [ctfont]
    movzx   esi, word [ctmp+8]
    xor     edx, edx
    CALLI   CTFontCreatePathForGlyph
    mov     [gpath], rax

    movzx   edi, byte [r13]
    mov     esi, GL_COMPILE
    CALLI   glNewList

    xorps   xmm0, xmm0                  ; flat, facing the camera - the same
    xorps   xmm1, xmm1                  ; normal WGL emitted with extrusion 0
    movss   xmm2, [f1_0]
    CALLI   glNormal3f

    cmp     qword [gpath], 0
    je      .noshape
    lea     rax, [vertbuf]
    mov     [verts], rax
    mov     byte [copen], 0
    mov     rdi, [tess]
    xor     esi, esi
    CALLI   gluTessBeginPolygon
    mov     rdi, [gpath]
    xor     esi, esi
    lea     rdx, [path_applier]
    CALLI   CGPathApply
    cmp     byte [copen], 0
    je      .nolast
    mov     rdi, [tess]
    CALLI   gluTessEndContour
.nolast:
    mov     rdi, [tess]
    CALLI   gluTessEndPolygon
.noshape:
    movss   xmm0, [g_adv]
    xorps   xmm1, xmm1
    xorps   xmm2, xmm2
    CALLI   glTranslatef
    CALLI   glEndList

    inc     r13
    dec     r12d
    jnz     .glyph

    pop     r13
    pop     r13
    pop     r12
    ret

; ---------------------------------------------------------------------------
;  CGPathApply's callback.  rdi = info (unused), rsi = const CGPathElement *,
;  which is { int type; CGPoint *points; } with CGPoint two CGFloat doubles.
;  Everything that has to survive a call into GLU lives in memory.
; ---------------------------------------------------------------------------
; CoreGraphics calls this from inside its own frame, so RBX and RBP hold its
; values, not ours: they are callee-saved, which means we have to put them back
; ourselves before any CALLI.
path_applier:
    push    rbx
    push    rbp
    push    r12
    lea     rbx, [imports + 128]
    lea     rbp, [kbase + 128]
    mov     eax, [rsi]
    mov     [pe_type], eax
    mov     rax, [rsi+8]
    mov     [pe_pts], rax

    cmp     dword [pe_type], 0
    je      .moveto
    cmp     dword [pe_type], 1
    je      .lineto
    cmp     dword [pe_type], 2
    je      .quadto
    cmp     dword [pe_type], 3
    je      .cubicto
    jmp     .done                       ; 4 = close; the next move ends it

.moveto:
    cmp     byte [copen], 0
    je      .noclose
    mov     rdi, [tess]
    CALLI   gluTessEndContour
.noclose:
    mov     rdi, [tess]
    CALLI   gluTessBeginContour
    mov     byte [copen], 1
.lineto:
    mov     rax, [pe_pts]
    movsd   xmm0, [rax]
    movsd   xmm1, [rax+8]
    movsd   [curx], xmm0
    movsd   [cury], xmm1
    call    emit_pt
    jmp     .done

; P(t) = (1-t)^2 P0 + 2(1-t)t C + t^2 P1
.quadto:
    mov     rax, [pe_pts]
    movsd   xmm0, [rax]
    movsd   [c1x], xmm0
    movsd   xmm0, [rax+8]
    movsd   [c1y], xmm0
    movsd   xmm0, [rax+16]
    movsd   [pex], xmm0
    movsd   xmm0, [rax+24]
    movsd   [pey], xmm0
    mov     r12d, 1
.qstep:
    call    seg_t                       ; xmm7 = t, xmm6 = 1-t
    movapd  xmm0, xmm6                  ; x
    mulsd   xmm0, xmm6
    mulsd   xmm0, [curx]
    movapd  xmm2, xmm6
    mulsd   xmm2, xmm7
    addsd   xmm2, xmm2
    movapd  xmm3, xmm2
    mulsd   xmm2, [c1x]
    addsd   xmm0, xmm2
    movapd  xmm2, xmm7
    mulsd   xmm2, xmm7
    movapd  xmm4, xmm2
    mulsd   xmm2, [pex]
    addsd   xmm0, xmm2
    movapd  xmm1, xmm6                  ; y
    mulsd   xmm1, xmm6
    mulsd   xmm1, [cury]
    mulsd   xmm3, [c1y]
    addsd   xmm1, xmm3
    mulsd   xmm4, [pey]
    addsd   xmm1, xmm4
    call    emit_pt
    inc     r12d
    cmp     r12d, FLATTEN_STEPS
    jle     .qstep
    jmp     .endseg

; P(t) = (1-t)^3 P0 + 3(1-t)^2 t C1 + 3(1-t) t^2 C2 + t^3 P1
.cubicto:
    mov     rax, [pe_pts]
    movsd   xmm0, [rax]
    movsd   [c1x], xmm0
    movsd   xmm0, [rax+8]
    movsd   [c1y], xmm0
    movsd   xmm0, [rax+16]
    movsd   [c2x], xmm0
    movsd   xmm0, [rax+24]
    movsd   [c2y], xmm0
    movsd   xmm0, [rax+32]
    movsd   [pex], xmm0
    movsd   xmm0, [rax+40]
    movsd   [pey], xmm0
    mov     r12d, 1
.cstep:
    call    seg_t
    movapd  xmm2, xmm6                  ; a = (1-t)^3
    mulsd   xmm2, xmm6
    mulsd   xmm2, xmm6
    movapd  xmm3, xmm6                  ; b = 3(1-t)^2 t
    mulsd   xmm3, xmm6
    mulsd   xmm3, xmm7
    mulsd   xmm3, [d_three]
    movapd  xmm4, xmm7                  ; c = 3(1-t) t^2
    mulsd   xmm4, xmm7
    mulsd   xmm4, xmm6
    mulsd   xmm4, [d_three]
    movapd  xmm5, xmm7                  ; d = t^3
    mulsd   xmm5, xmm7
    mulsd   xmm5, xmm7
    movapd  xmm0, xmm2
    mulsd   xmm0, [curx]
    movapd  xmm1, xmm3
    mulsd   xmm1, [c1x]
    addsd   xmm0, xmm1
    movapd  xmm1, xmm4
    mulsd   xmm1, [c2x]
    addsd   xmm0, xmm1
    movapd  xmm1, xmm5
    mulsd   xmm1, [pex]
    addsd   xmm0, xmm1
    mulsd   xmm2, [cury]
    mulsd   xmm3, [c1y]
    addsd   xmm2, xmm3
    mulsd   xmm4, [c2y]
    addsd   xmm2, xmm4
    mulsd   xmm5, [pey]
    addsd   xmm2, xmm5
    movapd  xmm1, xmm2
    call    emit_pt
    inc     r12d
    cmp     r12d, FLATTEN_STEPS
    jle     .cstep

.endseg:
    movsd   xmm0, [pex]
    movsd   [curx], xmm0
    movsd   xmm0, [pey]
    movsd   [cury], xmm0
.done:
    pop     r12
    pop     rbp
    pop     rbx
    ret

; xmm7 = r12 / FLATTEN_STEPS, xmm6 = 1 - that
seg_t:
    cvtsi2sd xmm7, r12d
    divsd   xmm7, [d_steps]
    movsd   xmm6, [d_one]
    subsd   xmm6, xmm7
    ret

; xmm0 = x, xmm1 = y.  The coordinates have to stay put until the polygon is
; tessellated, so each one gets its own slot in vertbuf.
emit_pt:
    sub     rsp, 8
    mov     rax, [verts]
    movsd   [rax], xmm0
    movsd   [rax+8], xmm1
    xorpd   xmm2, xmm2
    movsd   [rax+16], xmm2
    add     qword [verts], 24
    mov     rdi, [tess]
    mov     rsi, rax
    mov     rdx, rax
    CALLI   gluTessVertex
    add     rsp, 8
    ret

; void combine(GLdouble coords[3], void *data[4], GLfloat w[4], void **out)
; Self-intersecting outlines need a new vertex; hand back another slot.
tess_combine:
    mov     rax, [verts]
    mov     r8, [rdi]
    mov     [rax], r8
    mov     r8, [rdi+8]
    mov     [rax+8], r8
    mov     r8, [rdi+16]
    mov     [rax+16], r8
    add     qword [verts], 24
    mov     [rcx], rax
    ret

section S_RODATA
align 8
s_fontname: db "Arial-BoldMT", 0
d_steps:    dq 8.0
d_three:    dq 3.0

section .bss
alignb 8
pe_pts:     resq 1
pe_type:    resd 1
copen:      resb 1
g_adv:      resd 1
c1x:        resq 1
c1y:        resq 1
c2x:        resq 1
c2y:        resq 1
pex:        resq 1
pey:        resq 1
