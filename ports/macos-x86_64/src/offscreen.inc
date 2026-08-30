; ---------------------------------------------------------------------------
;  Verification build (-DOFFSCREEN=1).
;
;  Rather than capturing the display, render into a framebuffer object and dump
;  a fixed set of frames as PPM plus the mixed tune as a WAV.  This is how the
;  port was checked without taking over the screen, and how the packed build is
;  checked against the linked one.
;
;  Each frame is rendered twice and only the second is kept: the intro places
;  the camera from the previous frame's dacamera, so a cold frame at an
;  arbitrary ts would be shot through the camera of the shot before it.
; ---------------------------------------------------------------------------

section .text

%define SHOT_W RENDER_W
%define SHOT_H RENDER_H
%define SHOT_COUNT 13

init_offscreen:
    push    r12
    lea     rdi, [pfattr_off]
    lea     rsi, [pixfmt]
    lea     rdx, [npix]
    CALLI   CGLChoosePixelFormat
    mov     rdi, [pixfmt]
    xor     esi, esi
    lea     rdx, [ctx]
    CALLI   CGLCreateContext
    mov     rdi, [ctx]
    CALLI   CGLSetCurrentContext

    mov     edi, 1
    lea     rsi, [fbo]
    CALLI   glGenFramebuffersEXT
    mov     edi, GL_FRAMEBUFFER_EXT
    mov     esi, [fbo]
    CALLI   glBindFramebufferEXT

    mov     edi, 1
    lea     rsi, [rbo]
    CALLI   glGenRenderbuffersEXT
    mov     edi, GL_RENDERBUFFER_EXT
    mov     esi, [rbo]
    CALLI   glBindRenderbufferEXT
    mov     edi, GL_RENDERBUFFER_EXT
    mov     esi, GL_RGBA8
    mov     edx, RENDER_W
    mov     ecx, RENDER_H
    CALLI   glRenderbufferStorageEXT
    mov     edi, GL_FRAMEBUFFER_EXT
    mov     esi, GL_COLOR_ATTACHMENT0
    mov     edx, GL_RENDERBUFFER_EXT
    mov     ecx, [rbo]
    CALLI   glFramebufferRenderbufferEXT

    mov     edi, 1
    lea     rsi, [dbo]
    CALLI   glGenRenderbuffersEXT
    mov     edi, GL_RENDERBUFFER_EXT
    mov     esi, [dbo]
    CALLI   glBindRenderbufferEXT
    mov     edi, GL_RENDERBUFFER_EXT
    mov     esi, GL_DEPTH_COMPONENT24
    mov     edx, RENDER_W
    mov     ecx, RENDER_H
    CALLI   glRenderbufferStorageEXT
    mov     edi, GL_FRAMEBUFFER_EXT
    mov     esi, GL_DEPTH_ATTACHMENT
    mov     edx, GL_RENDERBUFFER_EXT
    mov     ecx, [dbo]
    CALLI   glFramebufferRenderbufferEXT
    pop     r12
    ret

; Frames come from a table instead of the clock, so runs are comparable.
get_ms:
    mov     eax, [shotidx]
    lea     rsi, [shot_ms]
    mov     eax, [rsi + rax*4]
    ret

grab_frame:
    push    r12
    cmp     byte [warm], 0
    jne     .doshot
    mov     byte [warm], 1              ; render this ts once more first
    pop     r12
    ret
.doshot:
    mov     byte [warm], 0
    xor     edi, edi
    xor     esi, esi
    mov     edx, SHOT_W
    mov     ecx, SHOT_H
    mov     r8d, GL_RGB
    mov     r9d, GL_UNSIGNED_BYTE
    lea     rax, [shotbuf]
    push    rax                         ; seventh argument
    push    rax                         ; and keep RSP aligned
    CALLI   glReadPixels
    add     rsp, 16

    mov     eax, [shotidx]              ; name the file shotNN.ppm
    mov     ecx, eax
    shr     ecx, 4
    add     ecx, '0'
    mov     [shotname+4], cl
    and     eax, 15
    cmp     eax, 9
    jle     .digit
    add     eax, 'a' - '0' - 10
.digit:
    add     eax, '0'
    mov     [shotname+5], al

    lea     rdi, [shotname]
    lea     rsi, [wbmode]
    CALLI   fopen
    mov     r12, rax

    lea     rdi, [ppmhdr]
    mov     esi, 1
    mov     edx, ppmhdr_len
    mov     rcx, r12
    CALLI   fwrite

    mov     r13d, SHOT_H - 1            ; glReadPixels hands back bottom-up
.row:
    imul    eax, r13d, SHOT_W*3
    lea     rdi, [shotbuf]
    add     rdi, rax
    mov     esi, 1
    mov     edx, SHOT_W*3
    mov     rcx, r12
    CALLI   fwrite
    dec     r13d
    jns     .row

    mov     rdi, r12
    CALLI   fclose

    inc     dword [shotidx]
    mov     eax, [shotidx]
    cmp     eax, SHOT_COUNT
    jae     exitIntro
    pop     r12
    ret

dump_wav:
    push    r12
    lea     rdi, [wavname]
    lea     rsi, [wbmode]
    CALLI   fopen
    mov     r12, rax
    lea     rdi, [wavhdr]
    mov     esi, 1
    mov     edx, 44
    mov     rcx, r12
    CALLI   fwrite
    lea     rdi, [pcmbuf]
    mov     esi, 1
    mov     edx, TOTAL_SAMPLES*2
    mov     rcx, r12
    CALLI   fwrite
    mov     rdi, r12
    CALLI   fclose
    pop     r12
    ret

section S_RODATA
align 8
pfattr_off: dd kCGLPFAAccelerated, kCGLPFAColorSize, 24, kCGLPFADepthSize, 32, 0
wbmode:     db "wb", 0
wavname:    db "song.wav", 0
ppmhdr:     db "P6", 10
            db %str(SHOT_W), " ", %str(SHOT_H), 10, "255", 10
ppmhdr_len  equ $ - ppmhdr

; 44-byte canonical WAV header, mono 16-bit at 44100 Hz
wavhdr:     db "RIFF"
            dd 36 + TOTAL_SAMPLES*2
            db "WAVEfmt "
            dd 16
            dw 1, 1
            dd SND_RATE, SND_RATE*2
            dw 2, 16
            db "data"
            dd TOTAL_SAMPLES*2

; One frame per camera, plus the titles, the destruction and the credits.
; ms = ts / 0.0495.
shot_ms:
            dd  15556       ; ts  770   the title, about to pass the camera
            dd  17172       ; ts  850   camera 0, dropping onto the city
            dd  21212       ; ts 1050   camera 1
            dd  25253       ; ts 1250   camera 2
            dd  29293       ; ts 1450   camera 3
            dd  49495       ; ts 2450   camera 4, street level
            dd  63636       ; ts 3150   the destruction front starts moving
            dd  70707       ; ts 3500   camera 4, mid-collapse
            dd  76768       ; ts 3800   camera 1 over the ruins
            dd  81818       ; ts 4050   camera 5, chasing Freddy
            dd  85859       ; ts 4250   camera 5
            dd  94949       ; ts 4700   credits, FROGZILLA
            dd 104040       ; ts 5150   credits, all five lines

section S_DATA
shotname:   db "shot00.ppm", 0

section .bss
alignb 16
shotbuf:    resb SHOT_W * SHOT_H * 3
shotidx:    resd 1
warm:       resb 1
fbo:        resd 1
rbo:        resd 1
dbo:        resd 1
