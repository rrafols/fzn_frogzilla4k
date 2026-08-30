; ---------------------------------------------------------------------------
;  Constants used by the intro: the OpenGL enums the original pulled from
;  OPENGL.INC, plus the CGL / CoreGraphics / CoreText / AudioToolbox values
;  that stand in for the Win32, GDI and DirectSound ones.
; ---------------------------------------------------------------------------

; -- OpenGL -----------------------------------------------------------------
%define GL_DEPTH_BUFFER_BIT     0x00000100
%define GL_COLOR_BUFFER_BIT     0x00004000
%define GL_QUADS                0x0007
%define GL_ZERO                 0
%define GL_ONE                  1
%define GL_SRC_ALPHA            0x0302
%define GL_COMPILE              0x1300
%define GL_UNSIGNED_BYTE        0x1401
%define GL_NORMALIZE            0x0BA1
%define GL_LIGHTING             0x0B50
%define GL_COLOR_MATERIAL       0x0B57
%define GL_DEPTH_TEST           0x0B71
%define GL_BLEND                0x0BE2
%define GL_TEXTURE_2D           0x0DE1
%define GL_LIGHT0               0x4000
%define GL_MODELVIEW            0x1700
%define GL_PROJECTION           0x1701
%define GL_RGB                  0x1907
%define GL_RGBA                 0x1908
%define GL_LINEAR               0x2601
%define GL_LINEAR_MIPMAP_LINEAR 0x2703
%define GL_TEXTURE_MAG_FILTER   0x2800
%define GL_TEXTURE_MIN_FILTER   0x2801
%define GL_TEXTURE_WRAP_S       0x2802
%define GL_TEXTURE_WRAP_T       0x2803
%define GL_CLAMP_TO_EDGE        0x812F
%define GL_RGBA8                0x8058
%define GL_GENERATE_MIPMAP      0x8191  ; GL_GENERATE_MIPMAP_SGIS in the original
%define GL_TEXTURE_FILTER_CONTROL 0x8500
%define GL_TEXTURE_LOD_BIAS     0x8501  ; GL_TEXTURE_LOD_BIAS_EXT
%define GL_DEPTH_COMPONENT24    0x81A6
%define GL_FRAMEBUFFER_EXT      0x8D40
%define GL_RENDERBUFFER_EXT     0x8D41
%define GL_COLOR_ATTACHMENT0    0x8CE0
%define GL_DEPTH_ATTACHMENT     0x8D00
%define GL_VIEWPORT             0x0BA2

; -- GLU tessellator --------------------------------------------------------
%define GLU_TESS_BEGIN          100100
%define GLU_TESS_VERTEX         100101
%define GLU_TESS_END            100102
%define GLU_TESS_COMBINE        100105
%define GLU_TESS_WINDING_RULE   100140
%define GLU_TESS_WINDING_NONZERO 100131

; -- CGL pixel format attributes --------------------------------------------
%define kCGLPFADoubleBuffer     5
%define kCGLPFAColorSize        8
%define kCGLPFADepthSize        12
%define kCGLPFAFullScreen       54
%define kCGLPFAAccelerated      73
%define kCGLPFADisplayMask      84
%define kCGLCPSwapInterval      222

; -- CoreGraphics / CoreFoundation ------------------------------------------
%define kCGEventSourceStateHIDSystemState  1
%define KEY_ESC                 53
%define kCFStringEncodingUTF8   0x08000100

; -- AudioToolbox -----------------------------------------------------------
%define kAudioFormatLinearPCM   0x6C70636D          ; 'lpcm'
%define kLinearPCMFormatFlagIsSignedInteger 4
%define kLinearPCMFormatFlagIsPacked        8

; ---------------------------------------------------------------------------
;  Intro parameters.  Everything here is the original's, except that the row
;  length is now expressed in samples instead of in a thread sleep.
; ---------------------------------------------------------------------------
%define NSAMPLES        8
%define NCHANNELS       8
%define CITY_WIDTH      9
%define CITY_HEIGHT     9
%define CANTONADES      2
%define CAR_NUM         3
%define R2T_SIZE        256             ; the render-to-texture glow source
%define RENDER_W        640             ; the resolution the original forced
%define RENDER_H        480

%define SND_RATE        44100
%define ORDERS          54
%define ROWS            12
; The module is speed 8, tempo 120: 2500/120*8 = 166.667 ms per row, which is
; exactly 7350 samples.  The original approximated it with a 160 ms thread
; sleep and then divided the visual clock by whatever it measured.
%define ROW_SAMPLES     7350
%define TOTAL_SAMPLES   (ORDERS * ROWS * ROW_SAMPLES)

; The largest instrument is 21250*16 bytes; one stride fits them all.
%define SAMP_STRIDE     340000
