# Frogzilla — macOS port

A port of the Fuzzion 4k intro *Frogzilla* (2004) from 32-bit Win32 assembly to
native 64-bit assembly for Intel macOS.

The original was NASM x86-32 talking to `CreateWindowEx` + WGL + DirectSound,
packed with 20to4 into a 4k self-extracting `.bat`. This is the same intro —
same city, same procedurally generated instruments, same module — rebuilt for
x86-64 Mach-O on top of CGL, CoreAudio and CoreText.

    make            # build the packed intro -> ./frogzilla
    ./frogzilla     # fullscreen; Esc quits, and it ends at 1:46

    make windowed   # -> build/frogzilla-windowed, a 1280x960 window

Requires an Intel Mac. Tested on macOS 15.7.4, Radeon Pro 575X.

Fullscreen is the packed build. Windowed goes through Cocoa — NSWindow and
NSOpenGLContext driven from assembly via `objc_msgSend`, because CGL can
capture a display but cannot make a window — which costs about 700 bytes, so it
is a separate build rather than a runtime flag.

## What had to change

| | Win32 original | macOS port |
|---|---|---|
| window | `CreateWindowEx` + `ChangeDisplaySettings` | `CGDisplayCapture` + `CGLSetFullScreenOnDisplay` |
| GL context | `wglCreateContext` / `wglMakeCurrent` | `CGLCreateContext` / `CGLSetCurrentContext` |
| text | `CreateFontA("arial")` + `wglUseFontOutlinesA` | CoreText outlines through the GLU tessellator |
| audio | 8 DirectSound buffers, pitch and volume per buffer | one pre-rendered AudioQueue buffer |
| player | thread waking every 160 ms, with the visual clock chasing it | tune mixed up-front, ts taken straight off the clock |
| calls | stdcall, arguments on the stack | System V AMD64, arguments in registers |
| imports | PE import table, or five DLLs walked by ordinal | `dlopen`/`dlsym` at start-up |
| exit key | `WM_KEYDOWN` | `CGEventSourceKeyState` |
| resolution | forced 640x480 mode | renders at 640x480, blitted up to the display |

Everything above the platform layer is the original code. The effects are the
same x87 arithmetic — `fsin`, the resonant low-pass in the sample generator,
the `fcomi`/`fcmov` clamps — because x86-64 still has the x87 unit, and its
results differ from the SSE equivalents in ways the intro depends on.

Three things genuinely had to be redesigned, and one detail of the 2004 pixel
format had to be reproduced deliberately.

### The text

`wglUseFontOutlinesA` is the whole credits sequence in one call: it asks GDI
for the outline of every character code, tessellates each into filled polygons
at em size 1.0, and compiles them into display lists 1..255, each ending with a
`glTranslatef` of the glyph's advance. `glCallLists` then draws a string by
walking its bytes.

macOS has nothing equivalent, so `src/text.inc` rebuilds those lists by hand.
CoreText hands over each glyph as a `CGPath`; `CGPathApply` walks it;
quadratic and cubic segments are flattened into eight line segments each; and
the GLU tessellator — whose begin, vertex and end callbacks are `glBegin`,
`glVertex3dv` and `glEnd` — turns the contours into triangles. With a
`glNewList` open, those land straight in the list, exactly as WGL did. The
winding rule is set to nonzero, which is what leaves the holes in O, R and G.

Only the sixteen letters the credits use are built, under their own character
codes, so `drawText` is unchanged. The font asked for is `Arial-BoldMT`, the
PostScript name of the Arial Bold the original requested; CoreText substitutes
if it is not installed.

This is the single most expensive thing in the port: about 650 packed bytes of
code plus its share of the import names.

### Audio

DirectSound gave every sample buffer its own playback rate and volume, and the
original just drove eight of them from a thread. CoreAudio has no equivalent,
so the mixing that DirectSound did is now explicit (`src/player.inc`): eight
voices with position, step and gain, rendered one row at a time into a single
AudioQueue buffer before the intro starts.

That also removes the player thread, and with it a feedback loop worth
explaining. The original's visual clock was `elapsed_ms / timeDivider`, and the
player thread rewrote `timeDivider` once a row so that `ts` tracked the row
counter: twelve rows — one order — advanced `ts` by 99. The row rate was
whatever `WaitForSingleObject(160)` actually delivered. Here the module's own
timing is used instead, speed 8 at tempo 120, which is 166.667 ms per row or
exactly 7350 samples, and `ts` is simply `ms * 0.0495`.

The original could be assembled for two DirectSound formats: 44100 mono, or
22050 stereo fed the same mono stream, which is what the .nfo means by "It will
sound better in XP than in 2K". This is the 44100 mono behaviour.

### The glow

The glow is the intro's whole look, and it is the one place where a detail of
the 2004 pixel format leaks into the effect. Pass three renders the scene
through `glBlendFunc(GL_SRC_ALPHA, GL_ZERO)`, so each colour is multiplied by
its own alpha and the palette's alphas — 0 for concrete, 64 for cars, 255 for
lights and text — pick out what is allowed to bleed. That result is read back
and added over the frame six times at rising mip levels.

The original reads it back as `GL_RGBA`, and its `PIXELFORMATDESCRIPTOR` asks
for `cAlphaBits` 0: the colour buffer has no alpha bitplanes, so every texel
arrives with alpha 1.0 and the `GL_SRC_ALPHA, GL_ONE` blend is plain addition.
A Mac drawable always has alpha, and so does the offscreen renderbuffer, so
reading RGBA here hands back what pass three actually wrote — alpha squared —
and the blend squares it again. The text, a large solid shape, survives that
almost unchanged; the street lights, a few per cent of the picture, disappear
entirely, and the city stops glowing. Reading and uploading `GL_RGB` puts the
sampled alpha back at 1 where the original had it.

One thing here is deliberately *not* faithful. Neither the original nor this
port ever set the glow texture's wrap mode, and the GL default is `GL_REPEAT`
— but the glow samples down to mip level six, four texels across, so a
bilinear tap at the edge of the screen-filling quad reaches straight into the
opposite edge of the picture. The bright far end of a street comes back as a
band along the bottom of the screen, and the sides bleed into each other. On
the frame at ts 1450 the bottom row of pixels was twenty-five times brighter
than the genuinely dark road thirty rows above it. `GL_CLAMP_TO_EDGE` on the
glow texture, set once at start-up, removes it for twenty bytes; the original
had the artefact and this port does not.

The blit needs the same treatment, and there it is an outright bug rather than
a judgement call, because the original has no blit at all. The quad that puts
the 640x480 frame on the display carries texture coordinates of exactly 0 and
1, so a `GL_LINEAR` tap at the border sits half a texel outside the image —
and under `GL_REPEAT` that half is fetched from the opposite edge. Measured on
the live window during the credits, where FROGZILLA runs off the right of the
screen, the leftmost pixel column read 124 against a background of 42: the
clipped letter's halo, arriving down the left border. Clamping `scenetex` as
well fixes it.

One consequence of the glow being right is that it is brighter and wider than
2004 hardware drew it, and it exposed the framing of the final title card.
`texsize[1]`, the z the credits' FROGZILLA settles at, was 9.5 in the original,
which puts the word at z -5.5 where the frustum is 3.038 half-widths across.
Arial Bold makes it 5.722 em wide starting at -2.6, so it ends at 3.122 — the
last A a few pixels past the right edge, with its halo cut on both sides. The
macOS port uses 8.5, which pulls it back to z -6.5 and puts the halo inside the
frame. Below that nothing more is gained: what still reaches the border is the
bloom off WONDER on the line underneath. The Win32 tree keeps 9.5.

### Aspect ratio

The original forced a 640x480 mode and hard-coded 4:3 into `gluPerspective`. A
modern Mac keeps its own resolution, so the intro renders into a 640x480 corner
of the back buffer and that corner is blitted, letterboxed, to the display.
Scaling the viewport instead would have changed what fraction of the picture
the 256x256 glow source covers, and the glow is the look.

## Two bugs in the original, kept and dropped

**The destruction test never branches.** `timeCalc` guards its Freddy
arithmetic with `fldz` / `fcomip st1` / `jl .noDestruction`, and FCOMIP clears
SF and OF, so `jl` is never taken. The destruction maths therefore runs from
the first frame. Before ts 3100 it puts Freddy tens of units away, where no
camera is pointing, so it never shows — and the port keeps it, because it is
what the intro computes.

**The x87 stack leaks.** The branch that never fires is also the one that would
have popped the value sitting under `FreddyPos`, so the original leaks one x87
register per frame, and the credits' z computation leaks a second one on each
of its two passes. Measured, this is harmless: the eight-deep stack wraps and
the stale slot is retaken before anything reads it, and the one frame after the
titles hand over to the city is the only one that comes out wrong. There is no
reason to reproduce it, so the port pops both.

## Size

The Win32 binary was 25085 bytes — 16 KB of which is a zero-filled import
scratch area — and 20to4 packed the party release into a 4084-byte `.bat`.
This one:

```
header + load commands    536
loader stub               168
intro, packed            5660   (11303 raw, 50.1%)
dyld bind opcodes          25
------------------------------
frogzilla                6389 bytes
```

It does not fit in 4096, and unlike the smaller Fuzzion intros the gap is not
only compression. Two costs are structural on macOS:

* **4096 bytes is the floor.** The kernel refuses to exec a Mach-O whose file
  is shorter than the page its first segment maps. The page is paid for whether
  or not it is used.
* **536 of it are mandatory.** `__PAGEZERO`, `__TEXT`, `__LINKEDIT`,
  `LC_DYLD_INFO_ONLY`, `LC_SYMTAB`, `LC_DYSYMTAB`, `LC_LOAD_DYLINKER`,
  `LC_MAIN`, `LC_BUILD_VERSION` and `LC_LOAD_DYLIB` are each load-bearing —
  drop `LC_DYSYMTAB` and dyld refuses the binary. The PE header the original
  used was smaller, and the intro hid strings in the unused parts of the DOS
  header.

Two tricks claw some of it back. `__LINKEDIT` is declared as an *empty* segment
based at the image address, which makes dyld resolve `LC_DYLD_INFO` offsets
against the first page — otherwise the bind opcodes need a second page. And the
intro unpacks into the zero-filled tail of `__TEXT` (`vmsize` simply exceeds
`filesize`), so there is no `mmap` and no second segment.

`make heatmap` measures what each block actually costs under the packer's own
settings, rather than its raw size:

| region | raw | packed |
|---|---|---|
| `_frame` — camera, the three passes, the credits | 1290 | 704 |
| import names | 1021 | 510 |
| `_start` — the dlopen/dlsym binder | 602 | 434 |
| music data (`zik.asm`) | 1152 | 420 |
| `rendersong` | 508 | 362 |
| `path_applier` — outline flattening | 684 | 308 |
| `init_text` | 513 | 276 |
| `gensample` | 503 | 272 |
| `drawBlock` | 530 | 249 |
| everything else | 5500 | 2125 |

The text machinery — `init_text`, `path_applier`, `emit_pt`, `tess_combine`,
and the CoreText and GLU names in `symnames` — is around 900 packed bytes, or a
sixth of the binary, to replace one Win32 call.

### oneKpaq

[oneKpaq](https://github.com/temisu/oneKpaq) is the live Crinkler-class packer
for macOS: PAQ-style context mixing, BSD-2. On a payload of this shape it beats
raw LZMA by around 8%. It ships a **32-bit** decompressor only, and macOS has
not run 32-bit code since Catalina, so `../../packers/onekpaq64/` holds a
64-bit port of it — 171 bytes, round-trip tested against the real encoder. The
build uses it when the encoder is available:

    ONEKPAQ=/path/to/onekpaq make

and falls back to the system LZMA otherwise, which costs about 300 bytes more.
Compression results are cached under `build/okp-cache/` by payload hash,
because an encoder run takes a long time. Build the encoder itself with `-O3
-march=native`: it ships `-Os`, optimised for *size*, for a compute-bound model
search.

## Verifying it

`make verify` builds the intro twice — linked, and packed — renders thirteen
frames from each into an offscreen framebuffer, and compares them:

    make verify

Nothing here is seeded from the wall clock: the intro reseeds its PRNG at fixed
points inside every frame, so all thirteen frames and the mixed tune have to
match byte for byte. This is how the port was developed without taking over the
display, and `build/contact.png` is a contact sheet of the result.

The frames are rendered twice each and only the second is kept, because the
intro places its camera from the *previous* frame's `dacamera`; a cold frame at
an arbitrary ts would be shot through the camera of the frame before it.

## Layout

```
src/intro.asm       entry, start-up, instruments, audio
src/frame.inc       the clock, the six cameras, the three passes, the credits
src/draw.inc        cube, city, cars, frog, glow, timeCalc, the blit
src/text.inc        glyph outlines: CoreText -> GLU tessellator -> display lists
src/sgen.inc        instrument synthesis  (ported from sgen_perxxor.asm)
src/player.inc      module playback and mixing  (replaces DirectSound)
src/offscreen.inc   the verification build
src/window.inc      windowed mode (Cocoa via objc_msgSend)
src/data.inc        constant pool, tables, BSS
src/macros.inc      calling conventions and the import table
src/imports.inc     the imported symbols, hot ones first
src/consts.inc      GL / GLU / CGL / CoreText / CoreAudio constants
src/stub.asm        loader stub for the packed build
src/onekpaq_decompressor64.asm   copy of ../../packers/onekpaq64/
tools/pack.py       builds the Mach-O and packs the intro
tools/heatmap.py    where the packed bytes go
tools/font5x7.py    a bitmap font, so the heatmap can label itself
```

The intro's content — the module, the instrument parameters and the camera
arrangement — is not here: it lives in `../../common/data/` and is shared with
the Win32 original. `../../common/tools/` holds the frame comparison and
contact sheet used by `make verify`, and `../../common/doc/` describes what the
intro does, which is the useful starting point for another port.

## Credits

Original intro by **Fuzzion**, 2004 — code by pain, bp and ufix, music by
wonder. Released at Euskal Encounter XII. This port keeps the original data
files intact.
