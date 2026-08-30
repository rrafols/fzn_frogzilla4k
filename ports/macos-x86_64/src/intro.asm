; ===========================================================================
;  "Frogzilla" - Fuzzion, 2004
;  macOS / x86-64 port of the original Win32 4k intro.
;
;  The effect code is the same x87 arithmetic as the original; what changed is
;  the platform underneath it:
;
;      CreateWindowEx + wgl   ->  CGL fullscreen on the captured main display
;      DirectSound, 8 buffers ->  one pre-rendered AudioQueue buffer
;      wglUseFontOutlines     ->  CoreText outlines through the GLU tessellator
;      stdcall (stack args)   ->  System V AMD64 (registers)
;      GetTickCount + thread  ->  a single monotonic clock
; ===========================================================================

bits 64
default rel

%ifndef DEBUG
  %define DEBUG 0
%endif
%ifndef OFFSCREEN
  %define OFFSCREEN 0
%endif
%ifndef TINY
  %define TINY 0
%endif
%ifndef WINDOWED
  %define WINDOWED 0
%endif

; The packed build is one flat RWX blob, so everything shares .text and only
; the zero-filled tail stays in .bss.
%if TINY
  %define S_RODATA .text
  %define S_DATA   .text
%else
  %define S_RODATA .rodata
  %define S_DATA   .data
%endif

%include "consts.inc"
%include "macros.inc"
%include "imports.inc"
%include "data.inc"

DECLARE_IMPORT_OFFSETS

%define CLOCK_UPTIME_RAW 8

%if TINY
[map symbols build/payload.map]
%endif

section .text
%if TINY
; The stub hands over dlsym in RDI and dlopen in RSI.
_start:
    and     rsp, -16
    mov     r13, rdi                    ; dlsym
    mov     r12, rsi                    ; dlopen

    lea     r15, [dylibs]               ; make the frameworks searchable
.opendylib:
    cmp     byte [r15], 0
    je      .dylibsdone
    mov     rdi, r15
    mov     esi, 1                      ; RTLD_LAZY
    call    r12
.skipdylib:
    mov     al, [r15]
    inc     r15
    test    al, al
    jnz     .skipdylib
    jmp     .opendylib

.dylibsdone:
    lea     r14, [imports]
    lea     r15, [symnames]
.resolve:
    cmp     byte [r15], 0
    je      .resolved
    mov     rdi, -2
    mov     rsi, r15
    call    r13
    mov     [r14], rax
    add     r14, 8
.skipname:
    mov     al, [r15]
    inc     r15
    test    al, al
    jnz     .skipname
    jmp     .resolve
.resolved:
    lea     rbx, [imports + 128]
    lea     rbp, [kbase + 128]
%else
global _main
_main:
    and     rsp, -16                    ; SysV wants 16-byte alignment at calls
    lea     rbx, [imports + 128]        ; hot imports reach via disp8
    lea     rbp, [kbase + 128]          ; the constant pool, likewise
%endif

; ---------------------------------------------------------------------------
;  Display and OpenGL context
; ---------------------------------------------------------------------------
%if OFFSCREEN
    call    init_offscreen
%elif WINDOWED
    call    init_window
%else
    CALLI   CGMainDisplayID
    mov     [dispid], eax
    mov     edi, eax
    CALLI   CGDisplayCapture

    mov     edi, [dispid]
    CALLI   CGDisplayIDToOpenGLDisplayMask
    mov     [dmask], eax

    lea     rdi, [pfattr]
    lea     rsi, [pixfmt]
    lea     rdx, [npix]
    CALLI   CGLChoosePixelFormat

    mov     rdi, [pixfmt]
    xor     esi, esi
    lea     rdx, [ctx]
    CALLI   CGLCreateContext

    mov     rdi, [ctx]
    CALLI   CGLSetCurrentContext
    mov     rdi, [ctx]
    mov     esi, [dmask]
    CALLI   CGLSetFullScreenOnDisplay

    mov     rdi, [ctx]                  ; wait for vblank on flush
    mov     esi, kCGLCPSwapInterval
    lea     rdx, [one_i]
    CALLI   CGLSetParameter

    ; Ask GL for the drawable it actually gave us rather than asking
    ; CoreGraphics for the display size - on a scaled HiDPI mode those are not
    ; the same number, and the viewport is what the image has to land in.
    mov     edi, GL_VIEWPORT
    lea     rsi, [vpbuf]
    CALLI   glGetIntegerv
    mov     r14d, [vpbuf+8]
    mov     r15d, [vpbuf+12]

    lea     rax, [r15*4]                ; the 4:3 box to blit into
    xor     edx, edx
    mov     ecx, 3
    div     rcx
    mov     r13, r15
    cmp     rax, r14
    jbe     .box
    mov     rax, r14
    lea     r13, [r14*2]
    add     r13, r14
    shr     r13, 2
.box:
    mov     [blitw], eax
    mov     [blith], r13d
    sub     r14, rax
    shr     r14, 1
    mov     [blitx], r14d
    sub     r15, r13
    shr     r15, 1
    mov     [blity], r15d

    call    make_tex
%endif

; ---------------------------------------------------------------------------
;  The glow texture wraps, and at the mip levels the glow reads - down to four
;  texels across - a bilinear tap at the edge of the quad pulls in the opposite
;  edge of the picture.  The bright end of a street then reappears as a band
;  along the bottom of the screen, and the sides smear into each other.  The
;  original left this at the GL default and had the same artefact; clamping is
;  the one place this port deliberately looks better than it did.
;  Texture object 0 is the glow's, and nothing else ever rebinds it.
; ---------------------------------------------------------------------------
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_WRAP_S
    mov     edx, GL_CLAMP_TO_EDGE
    CALLI   glTexParameteri
    mov     edi, GL_TEXTURE_2D
    mov     esi, GL_TEXTURE_WRAP_T
    mov     edx, GL_CLAMP_TO_EDGE
    CALLI   glTexParameteri

; ---------------------------------------------------------------------------
;  The frog's quadric, and the glyph display lists
; ---------------------------------------------------------------------------
    CALLI   gluNewQuadric
    mov     [quadric], rax
    call    init_text

; ---------------------------------------------------------------------------
;  Instruments and the note frequency table.  holdrand is still zero here,
;  exactly as in the original, so the noise in the instruments is the same
;  every run.
; ---------------------------------------------------------------------------
    xor     esi, esi
.gensamples:
    push    rsi
    push    rsi
    call    gensample
    pop     rsi
    pop     rsi
    inc     esi
    cmp     esi, NSAMPLES
    jne     .gensamples

    ; C-5 comes out at the sample rate, and each entry is a semitone above
    ; the last - the same table the original built for DirectSound's
    ; SetFrequency, in Hz.
    fld     dword [c33152]
    lea     rdi, [freqtable]
    mov     ecx, 8*12
.genfreq:
    fist    dword [rdi]
    add     rdi, 4
    fmul    dword [c105]
    dec     ecx
    jnz     .genfreq
    fstp    st0

; ---------------------------------------------------------------------------
;  Audio: render the tune into one queue buffer and start it.
; ---------------------------------------------------------------------------
%if OFFSCREEN
    lea     rdi, [pcmbuf]
    call    rendersong
    call    dump_wav
%else
    movsd   xmm0, [d_rate]
    movsd   [asbd], xmm0
    lea     rdi, [asbd]
    lea     rsi, [aq_callback]
    xor     edx, edx
    xor     ecx, ecx
    xor     r8d, r8d
    xor     r9d, r9d
    lea     rax, [aq]
    push    rax                         ; 7th argument: &queue
    push    rax                         ; also keeps RSP aligned
    CALLI   AudioQueueNewOutput
    add     rsp, 16

    mov     rdi, [aq]
    mov     esi, TOTAL_SAMPLES * 2
    lea     rdx, [aqbuf]
    CALLI   AudioQueueAllocateBuffer

    mov     rax, [aqbuf]
    mov     dword [rax+16], TOTAL_SAMPLES * 2
    mov     rdi, [rax+8]
    call    rendersong

    mov     rdi, [aq]
    mov     rsi, [aqbuf]
    xor     edx, edx
    xor     ecx, ecx
    CALLI   AudioQueueEnqueueBuffer
    mov     rdi, [aq]
    xor     esi, esi
    CALLI   AudioQueueStart
%endif

; ---------------------------------------------------------------------------
    mov     edi, CLOCK_UPTIME_RAW
    CALLI   clock_gettime_nsec_np
%ifdef START_MS
    ; -DSTART_MS=n starts the visuals n milliseconds in, which is the only
    ; practical way to look at something 95 seconds into a 106-second intro.
    ; The tune still starts from the top.
    mov     rcx, START_MS * 1000000
    sub     rax, rcx
%endif
    mov     [t_start], rax

%include "frame.inc"

; ---------------------------------------------------------------------------
exitIntro:
%if OFFSCREEN || WINDOWED
    xor     edi, edi
    CALLI   exit
%else
    mov     edi, [dispid]
    CALLI   CGDisplayRelease
    xor     edi, edi
    CALLI   exit
%endif

; AudioQueue insists on a callback; the buffer is never recycled, so it is
; only ever reached when playback of the whole tune finishes.
aq_callback:
    ret

%if OFFSCREEN == 0
; Milliseconds since the intro started.
get_ms:
    push    rax
    mov     edi, CLOCK_UPTIME_RAW
    CALLI   clock_gettime_nsec_np
    sub     rax, [t_start]
    xor     edx, edx
    mov     ecx, 1000000
    div     rcx
    pop     rdx
    ret
%endif

%include "draw.inc"
%include "text.inc"
%include "sgen.inc"
%include "player.inc"
%if OFFSCREEN
  %include "offscreen.inc"
%endif
%if WINDOWED
  %include "window.inc"
%endif

; ---------------------------------------------------------------------------
;  Data
; ---------------------------------------------------------------------------
section S_RODATA
align 4
%include "samples.inc"
%include "zik.asm"

section S_DATA
align 8
%if TINY
    EMIT_IMPORT_NAMES
dylibs:
    db "/System/Library/Frameworks/OpenGL.framework/OpenGL", 0
    db "/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", 0
    db "/System/Library/Frameworks/CoreText.framework/CoreText", 0
    db "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", 0
    db "/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", 0
    db 0
%else
    EMIT_IMPORT_TABLE
%endif

; Everything zero-filled goes here, and bss_end closes it: the packer sizes
; __TEXT's vmsize from that symbol, so anything declared past it would land
; outside the mapping and in the heap.
section .bss
alignb 16
%if OFFSCREEN
pcmbuf:     resb TOTAL_SAMPLES * 2
%endif
%if TINY
imports:    resq IMPORT_COUNT
%endif
alignb 16
bss_end:
