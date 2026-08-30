; ---------------------------------------------------------------------------
;  Constant pool, hot variables, and the tables the effects read.
;
;  The Win32 original could hand a float straight to the API as a
;  "push dword <bits>" immediate.  SysV wants it in an XMM register, which
;  would mean a rip-relative load with a four-byte displacement at every one
;  of some 400 sites - long, and (because every displacement differs) close to
;  incompressible.
;
;  So the values the effects touch constantly live in one block with RBP parked
;  in the middle of it: RBP needs neither a REX prefix nor a SIB byte, so a
;  pool access is three bytes shorter than the rip-relative form.  POOL both
;  reserves the slot and defines the name, and NASM picks disp8 or disp32 by
;  itself, which means the ordering below is a size optimisation and nothing
;  more - the first 256 bytes are the ones worth spending.
; ---------------------------------------------------------------------------

%define K(x) rbp + (x - kbase - 128)

%macro POOL 2                           ; 32-bit slot: float, or fild dword
  K_ %+ %1: dd %2
  %xdefine %1 K(K_ %+ %1)
%endmacro

%macro POOLW 2                          ; 16-bit slot: fild / fimul / fidiv word
  K_ %+ %1: dw %2
  %xdefine %1 K(K_ %+ %1)
%endmacro

section S_DATA
align 16
kbase:
; -- x87 -> XMM hand-over slots, and the integer scratch -------------------
    POOL  fp0, 0
    POOL  fp1, 0
    POOL  fp2, 0
    POOL  fp3, 0
    POOL  wTemp, 0
; -- cubeTS's saved arguments: the six floats every solid in the city goes
;    through, so these are the hottest addresses in the intro ---------------
    POOL  ct0, 0
    POOL  ct1, 0
    POOL  ct2, 0
    POOL  cs0, 0
    POOL  cs1, 0
    POOL  cs2, 0
; -- per-frame working values (the original's globals) ---------------------
    POOL  v_ts, 0                       ; the visual clock
    POOL  holdrand, 0                   ; myRandFloat's state
    POOL  destruct, 0
    POOL  height, 0
    POOL  tmpd2, 0
; -- the constants the drawing code leans on -------------------------------
    POOL  f0_0, 0.0
    POOL  f1_0, 1.0
    POOL  f0_24, 0.24                   ; BL_DISP, the city's grid pitch
    POOL  f90_0, 90.0
    POOL  f0_5, 0.5
    POOL  f0_2, 0.2
    POOL  f0_4, 0.4
    POOL  f0_3, 0.3
    POOL  f0_1, 0.1
    POOL  f0_05, 0.05
    POOL  f0_02, 0.02
    POOL  f0_018, 0.018
    POOL  f0_001, 0.001
    POOLW i3, 3
    POOLW i7, 7
    POOLW i8, 8
    POOLW i11, 11
    POOLW i18, 18
    POOLW i30, 30
    POOLW i67, 67
    POOLW i70, 70
    POOLW i100, 100
    POOLW i127, 127
    POOLW i32767, 32767
; -- the solids -------------------------------------------------------------
    POOL  f0_055, 0.055
    POOL  f0_007, 0.007
    POOL  f0_01, 0.01
    POOL  f0_0015, 0.0015              ; also fcarvelcant
    POOL  f0_0012, 0.0012
    POOL  f0_003, 0.003
    POOL  f0_06, 0.06
    POOL  f0_03, 0.03
    POOL  fm0_03, -0.03
    POOL  f0_065, 0.065
    POOL  f0_002, 0.002
    POOL  f0_0715, 0.0715
    POOL  f0_04, 0.04
; -- timeCalc's outputs -----------------------------------------------------
    POOL  dacamera, 0
    POOL  carrotate, 0
    POOL  dtime0, 0
    POOL  dtime1, 0
    POOL  doffset, 0
    POOL  delta, 0
    POOL  ncars, 0
    POOL  FreddyPos, 0
    POOL  FreddyAlt, 0
    POOL  f1_5, 1.5
    POOL  f1_2, 1.2
; ---- past here the displacement is four bytes, which is fine: everything
;      below is either once per frame or once per run ----------------------
    POOLW i20, 20
    POOLW i445, 445
    POOLW i800, 800
    POOLW i1000, 1000
    POOLW i1165, 1165
    POOLW i2600, 2600
    POOLW i2850, 2850
    POOLW i3100, 3100
    POOLW i4200, 4200
    POOLW i4700, 4700
    POOLW i4750, 4750
    POOL  f2_0, 2.0
    POOL  f1_333, 1.333
    POOL  f1000_0, 1000.0
    POOL  fm1_0, -1.0
    POOL  fm1_11, -1.11
    POOL  f50_0, 50.0
    POOL  fm1_85, -1.85
    POOL  f40_0, 40.0
    POOL  fm0_37, -0.37
    POOL  f30_0, 30.0
    POOL  f25_0, 25.0
    POOL  fm0_1, -0.1
    POOL  f0_84, 0.84
    POOL  fm90_0, -90.0
    POOL  f0_004, 0.004
    POOL  fm0_008, -0.008
    POOL  f0_0025, 0.0025
    POOL  f0_0061, 0.0061
    POOL  f0_0003, 0.0003
    POOL  fm0_002, -0.002
    POOL  f0_0057, 0.0057
    POOL  fm28_65, -28.65
    POOL  f0_0022, 0.0022
    POOL  f0_0088, 0.0088
    POOL  fm0_0048, -0.0048
    POOL  fm22_92, -22.92
    POOL  f0_0024, 0.0024
    POOL  f0_006, 0.006
    POOL  fm0_0006, -0.0006
    POOL  f51_57, 51.57
    POOL  fm1_2, -1.2
    POOL  fm0_5, -0.5
    POOL  fm0_665, -0.665
    POOL  fm0_003, -0.003
    POOL  fcarfase, 0.0375              ; carFase * carVel / cantonades
; -- the car arrangement, CAR_NUM * 4 offsets, written by timeCalc ----------
K_caroffsets:
    times CAR_NUM * 4 dd 0
    %define caroffsets K(K_caroffsets)
; -- sample generator -------------------------------------------------------
    POOL  sg_store, 0                   ; the original's perxxorVars, in order
    POOL  sg_f, 0
    POOL  sg_q, 0
    POOL  sg_fVal, 0
    POOL  sg_fdVal, 0
    POOL  sg_dcut, 0
    POOL  sg_dres, 0
    POOL  sg_amp, 0
    POOL  sg_damp, 0
    POOL  sg_n, 0                       ; nSamples, as a dword for fidiv
    POOL  f_inv16M, 0.00000095367431640625
    POOL  f0_0019274, 0.0019274376417233560090702947845805
    POOL  f2pi44100, 1.4247585730565955729989312395825e-4
    POOL  f2_65, 0.000030517578125
kend:

; -- referenced a handful of times, so plain rip-relative is fine -----------
section S_RODATA
align 8
c33152:     dd 1378.125             ; so that C-5 comes out at the sample rate
c105:       dd 1.05946309436        ; one semitone
ts_scale:   dd 0.0495               ; ts per millisecond: 8.25 rows / 166.667 ms
rate_f:     dd 44100.0
mastergain: dd 56.0             ; peaks at about 29500 of 32767
one_i:      dd 1
; DirectSound volumes are hundredths of a decibel; these are the same four
; values as the original's "vols", turned into linear gain.
volgain:    dd 0.25118864, 0.50003457, 0.74989421, 1.0
d_fovy:     dq 45.0                 ; the original pushed these as raw doubles
d_znear:    dq 0.06999999843
d_zfar:     dq 80.0

; -- the frog: nine spheres, each placed relative to the one before ---------
align 4
ranapx:     dd  0.0, -0.189,  0.00,  0.414,  0.0,  0.045,   0.00, 0.081, 0.00
ranapy:     dd -0.09, -0.18,  0.00,  0.00,   0.00, 0.378,   0.00, 0.00,  0.00
ranapz:     dd  0.0,   0.18, -0.36,  0.36,  -0.36, 0.342, -0.324, 0.306, -0.288
ranarad:    dd  0.315, 0.225, 0.225, 0.1215, 0.1215, 0.1332, 0.099, 0.063, 0.045
ranarc:     db  2,2,2,2,2,1,1,0,0

; -- the credits ------------------------------------------------------------
;  The third column is a z offset, not a size: it is how far towards the camera
;  each string is pulled once the fly-in has settled.
;
;  FROGZILLA's was 9.5 in the original, which puts it at z -5.5, where the
;  frustum is 3.038 half-widths across.  Arial Bold makes the word 5.722 em
;  wide and it starts at -2.6, so it ends at 3.122: the last A is a few pixels
;  over the right edge, and its halo is cut off on both sides.  That is the
;  original's own framing and it is off-centre by 0.26 em, but the glow here is
;  brighter and wider than 2004 hardware drew it, so the clipping shows.  8.5
;  pulls it back to z -6.5 and the halo lands inside the frame; below that
;  nothing further is gained, because what still reaches the border is the
;  bloom off "WONDER" on the line underneath.
textos:     db "FUZZIONFROGZILLABPUFIXPAINWONDER"
textoffset: db 0,7,16,18,22,26,32
texxpos:    dd -2.0, -2.6, -6.0, -4.0, -1.0,  2.0
texypos:    dd -0.3,  0.0, -3.0, -3.0, -3.0, -3.0
texsize:    dd -1.0,  8.5,  2.0,  2.0,  2.0,  2.0

; -- palette (RGBA bytes, handed to glColor4ubv) ----------------------------
Colors:
zerov:      db 000, 000, 000, 000
            db 255, 255, 255, 064
            db 000, 200, 000, 128
fanal:      db 204, 204, 204, 000
colorBlock: db 051, 051, 064, 000
clGlass:    db 051, 025, 025, 000
carColors:  db 170, 000, 000, 064
            db 200, 200, 000, 064
            db 000, 145, 064, 064
            db 120, 100, 120, 064
            db 020, 000, 100, 064
            db 200, 100, 000, 064
            db 080, 100, 150, 064
            db 090, 150, 064, 064
edifCol:    db 080, 080, 080, 000
            db 040, 040, 040, 000
onev:       db 255, 255, 255, 255
fontcolor:  db 128, 255, 051, 255

; -- the unit cube: six faces, each a normal followed by four corners -------
;    Exactly the vertex order the original pushed onto the stack.
align 4
cubeverts:
    dd  0.0,  0.0, -1.0
    dd -1.0, -1.0, -1.0
    dd  1.0, -1.0, -1.0
    dd  1.0,  1.0, -1.0
    dd -1.0,  1.0, -1.0

    dd  1.0,  0.0,  0.0
    dd  1.0, -1.0, -1.0
    dd  1.0,  1.0, -1.0
    dd  1.0,  1.0,  1.0
    dd  1.0, -1.0,  1.0

    dd -1.0,  0.0,  0.0
    dd -1.0, -1.0, -1.0
    dd -1.0,  1.0, -1.0
    dd -1.0,  1.0,  1.0
    dd -1.0, -1.0,  1.0

    dd  0.0,  0.0,  1.0
    dd -1.0, -1.0,  1.0
    dd  1.0, -1.0,  1.0
    dd  1.0,  1.0,  1.0
    dd -1.0,  1.0,  1.0

    dd  0.0, -1.0,  0.0
    dd -1.0, -1.0, -1.0
    dd -1.0, -1.0,  1.0
    dd  1.0, -1.0,  1.0
    dd  1.0, -1.0, -1.0

    dd  0.0,  1.0,  0.0
    dd -1.0,  1.0, -1.0
    dd -1.0,  1.0,  1.0
    dd  1.0,  1.0,  1.0
    dd  1.0,  1.0, -1.0

; -- the camera arrangement, shared with the Win32 tree ---------------------
%macro CAM 1
    db %1
%endmacro
align 4
camera_table:
%include "cameras.inc"

; -- CGL pixel format request -----------------------------------------------
section S_DATA
align 8
pfattr:     dd kCGLPFADoubleBuffer
            dd kCGLPFAFullScreen
            dd kCGLPFAAccelerated
            dd kCGLPFADisplayMask
dmask:      dd 0                    ; patched with the real display mask
            dd kCGLPFAColorSize, 24
            dd kCGLPFADepthSize, 32
            dd 0
d_aspect:   dq 1.3333333730697632   ; the original's hard-coded 4:3

; -- AudioStreamBasicDescription: 44100 Hz, mono, signed 16-bit packed ------
asbd:       dq 0                    ; mSampleRate, filled at start-up
            dd kAudioFormatLinearPCM
            dd kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
            dd 2                    ; mBytesPerPacket
            dd 1                    ; mFramesPerPacket
            dd 2                    ; mBytesPerFrame
            dd 1                    ; mChannelsPerFrame
            dd 16                   ; mBitsPerChannel
            dd 0                    ; mReserved
d_rate:     dq 44100.0
d_one:      dq 1.0
d_nonzero:  dq 100131.0             ; GLU_TESS_WINDING_NONZERO, as a GLdouble

section .bss
alignb 16
sampbuf:    resb NSAMPLES * SAMP_STRIDE     ; the eight generated instruments
freqtable:  resd 96
voices:     resd NCHANNELS * 4              ; index, position, step, gain
da_pixels:  resb R2T_SIZE * R2T_SIZE * 3    ; the glow source, read back per frame
quadric:    resq 1                          ; the GLU quadric the frog is made of
tess:       resq 1                          ; the GLU tessellator, start-up only
ctfont:     resq 1
gpath:      resq 1
verts:      resq 1                          ; -> vertbuf, bumped while flattening
curx:       resq 1                          ; the path pen, as CGFloat doubles
cury:       resq 1
vertbuf:    resq 3 * 6000                   ; flattened outline, GLdouble[3]
ctmp:       resq 8                          ; CoreText scratch (glyph, advance)

ctx:        resq 1                          ; CGLContextObj
pixfmt:     resq 1
npix:       resq 1
aq:         resq 1                          ; AudioQueueRef
aqbuf:      resq 1                          ; AudioQueueBufferRef
t_start:    resq 1                          ; clock at start, nanoseconds
dispid:     resd 1
scenetex:   resd 1                          ; the 640x480 frame, as a texture
vpbuf:      resd 4                          ; the drawable GL handed us
blitx:      resd 1                          ; where it lands on the display
blity:      resd 1
blitw:      resd 1
blith:      resd 1
