# What Frogzilla does

Everything here is derived from the December 2004 Win32 source, and is what a
port has to reproduce. Numbers are the ones in the code, not approximations.

## The clock

There is one number, `ts`, and everything is a function of it.

In the original, `ts = elapsed_ms / timeDivider`, and the music thread rewrote
`timeDivider` once per row so that `ts` tracked the module's row counter:
`timeDivider = elapsed_ms / (rows * 8.25)`. Twelve rows — one order — advance
`ts` by 99. The row period was whatever `WaitForSingleObject(160)` delivered.

The module is speed 8 at tempo 120, so a row is `2500/120*8` = 166.667 ms, and
the loop was converging on `ts = ms * 8.25 / 166.667` = `ms * 0.0495`. A port
that mixes the tune up front can use that directly.

`dacamera = round((ts - 800) / 100)` selects the camera. The intro ends when
`dacamera >= 45`, that is at ts 5250, about 106 seconds in. The tune is 54
orders long, 108 seconds, so it outlives the visuals by two.

## The three phases

| ts | phase | what is drawn |
|---|---|---|
| < 800 | 0 | the title, nothing else |
| 800 .. 4300 | 1 | the city |
| > 4300 | 2 | the credits |

## The three passes

Every frame draws its scene three times, counting down:

* **pass 3** into a 256x256 viewport, then `glReadPixels` + `glTexImage2D`
  into a 256x256 texture with mipmap generation on. The viewport is cleared
  and reset to the render size afterwards. This is the glow source.
* **pass 2** at the render size, followed by the glow: six screen-filling
  quads of that texture, blended `GL_SRC_ALPHA, GL_ONE`, at
  `GL_TEXTURE_LOD_BIAS` 1 through 6.
* **pass 1** the scene once more — for the city, nothing; for the text, the
  text again.

Blending is `GL_SRC_ALPHA, GL_ZERO` while the passes draw, so **the alpha
channel of each colour decides what glows**: alpha 0 renders black into the
glow source, alpha 255 renders at full brightness. That is why the palette
carries alphas of 0, 64, 128 and 255 rather than being opaque throughout.

The alpha is applied **once**, there and nowhere else. The original reads the
glow source back as `GL_RGBA`, but its `PIXELFORMATDESCRIPTOR` asks for
`cAlphaBits` 0, so the colour buffer has no alpha bitplanes and every texel
comes back with alpha 1.0; `GL_SRC_ALPHA, GL_ONE` is then plain addition. A
port whose framebuffer *does* carry alpha will read back what the pass wrote —
alpha squared — and multiply by it a second time, which leaves the text (a
large, solid shape) looking about right and makes the street lights, a few per
cent of the picture, vanish. Upload the glow source without an alpha channel.

Neither the original nor the macOS port sets the glow texture's wrap mode, and
the GL default is `GL_REPEAT`. Since the glow samples down to four texels
across, that puts the opposite edge of the picture into every edge of the
screen — most visibly as a bright band along the bottom. The original shipped
with it; the macOS port sets `GL_CLAMP_TO_EDGE` instead. Either is defensible,
but decide on purpose.

Only pass 3 is drawn in colour. Passes 2 and 1 start from `glColor4ubv(zerov)`,
which is `0,0,0,0`, so the text in those passes is a black silhouette punched
out of its own halo. Lighting is off for pass 3 and on for pass 2, because each
pass leaves the state the next one inherits.

The projection is `gluPerspective(45, 1.3333, 0.07, 80)`, fixed.

## The camera

`common/data/cameras.inc` maps `dacamera` to one of six camera setups. Below
`dacamera` 0 and from 36 up, no camera transform is applied at all.

| | |
|---|---|
| 0 | `translate(0, 1.5 - ts*0.001, -1)`, `rotate(90, X)` — sliding down onto the grid |
| 1 | `translate(0,0,-1.11)`, `rotate(50, X)`, `rotate(ts*0.3, Y)` |
| 2 | `translate(0,0.3,-1.85)`, `rotate(ts/70, Y)`, `rotate(40, X)` |
| 3 | `translate(0,0,-0.37)`, `rotate(30, X)`, `rotate(ts*0.3, Y)` |
| 4 | `rotate(25, X)`, `translate(0.84, -0.1, 1.5 - (caroffsets[1]+dtime0)*0.48)` — riding with the traffic |
| 5 | `translate(0, -(FreddyAlt+0.2), -(FreddyPos+1.2))`, `rotate(25, X)`, `rotate(-90, Y)` — chasing the frog |

From `dacamera` 20 on, a `translate(0, sin(x)/x/100, 0)` shudder is applied
first, where `x = (ts - 800) - dacamera*100` — a shock at each camera change
that decays before the next.

The camera is placed from the *previous* frame's `dacamera`, and `timeCalc`
runs after it, so camera 5 also follows Freddy one frame late. It is a frame,
and it does not show; but a port that renders isolated frames has to render
each one twice to get its camera right.

## timeCalc

All from `ts`:

```
delta      = (ts - 3100) / 100                      the destruction clock
FreddyPos  = (floor(delta) + clamp01(2*(delta - floor(delta))) - 8) * 0.24
FreddyAlt  = clamp(0.4 * sin(2*pi*delta), 0, 1000)
carrotate  = clamp((ts - 2850 + 20) * 1.5, 0, 30)   how hard cars spin
doffset    = clamp(ts, 0, 2850)                     the traffic freezes at 2850
dtime0     = floor(doffset * 0.0015)                whole laps
dtime1     = doffset * 0.0015 - dtime0              the fraction of this one
caroffsets[cepos*4 + cedge] = clamp01((dtime1 - cepos*0.0375 - ((cedge&1) ? 0 : 0.5)) / 0.4)
```

`floor` is really `round(x - 0.5)`, and `clamp01(x)` clamps to `[0,1]`. So
Freddy hops once per unit of `delta`: `FreddyPos` steps forward in half the
period and holds for the other half, while `FreddyAlt` traces the arc. Before
ts 3100 `delta` is negative, which puts him tens of units away — see the note
in the macOS port's README about the test that was meant to skip this.

## The city

A 9x9 grid on 0.24 centres, on a ground slab scaled `(2, 0.004, 1.2)`.

Per block, at grid position (i, j) — i runs along X, j along Z, both 0..8, and
the block sits at `((i-4)*0.24, 0, (j-4)*0.24)`:

```
destruct = (ts - 3100)*0.05 - (i*5 + 11)      the front sweeps along X
if (|j - 4| & 254) != 0:  destruct = 0        only the middle three rows fall
height   = round(|rand()| * 7) + 1            1..8 floors
```

Freddy hops along X too, so the front is the wake he leaves behind him.

Four sides, each with three street lamps that tip over by
`clamp((destruct - height)*8, 0, 30)` degrees, and then `height` floors, each
rotated `i*90` degrees about Y and tipped by
`clamp((destruct + floor - height)*18, 0, 67)` degrees. Each floor carries four
faces of five windows; a window is lit if the PRNG says so **and** its floor has
not started to fall.

`rand()` is Microsoft's LCG — `holdrand = holdrand*214013 + 2531011` — read as
the low sixteen bits, signed, divided by 32767, so it lands in `[-1,1)`.
`holdrand` is reset to 2 at the top of each pass and to 14 before the city is
drawn, which is what keeps the skyline and the window pattern stable from frame
to frame. `drawMultiVehicle` reseeds it per intersection from
`dtime0*2 + zcpos + xcpos`, so the traffic is stable too and simply advances as
`dtime0` does.

The cars are eight stacked boxes each, in eight colours, on a 9x11 grid of
intersections with four edges apiece and `round(|rand()|*4) - 1` cars per edge
(at least one — the loop is do-while). Each is spun by `carrotate * rand()`,
which is zero until ts 2830 and then ramps to 30 degrees: the crash.

## Freddy

Nine `gluSphere`s of 20x20, radii 0.315 down to 0.045, in three colours. The
modelview is *not* pushed between them, so each translation is relative to the
one before; the offsets in `ranapx/y/z` are deltas, not positions. Read them in
order or the frog falls apart.

## The text

`FUZZIONFROGZILLABPUFIXPAINWONDER`, cut into six strings by
`textoffset = 0,7,16,18,22,26,32`. Each is drawn at
`translate(texxpos[i], texypos[i], texsize[i])` — the third column is a z
offset, not a size — inside a global `translate(0, 0, z)` where

```
k = (ts > 2600) ? 2600 : -1435
z = |min(ts, 4750) - k| * 0.2 - 445
```

so the titles fly at the camera and pass through it around ts 790, and the
credits do the same again from ts 4300 on. `texsize[1]` is 9.5 in the original,
which leaves the final A of FROGZILLA a few pixels past the right edge of a
4:3 frustum; the macOS port uses 8.5 so the glow around it stays in frame. Which strings are up:

```
first = round(ts / 4200)                            0 = titles, 1 = credits
count = clamp(round((ts - 4700)/100), 0, 4) + 1
```

The glyphs are Arial Bold outlines at em size 1.0, filled, drawn unlit with
depth testing off — one display list per character code, each ending with a
translate of the glyph's advance, so a string is one `glCallLists` over its
bytes.

## The music

`zik.asm` is a "suxored" module: 54 orders, 12 rows each, 8 channels.

* `orderList[54]` — one byte per order, an index into `patternList`
* `patternList[15][8]` — for each pattern, the channel record used by each of
  the eight channels, or 255 for silence
* `channelList[40][25]` — one instrument byte, then twelve note bytes, then
  twelve effect bytes

A note byte is `note | octave<<4 | volume<<6`:

| field | meaning |
|---|---|
| note 0 | nothing on this row |
| note 1..12 | semitone, 1 = C |
| note 15 | note cut |
| octave 0..3 | plus the module's base octave, 3 |
| volume 0..3 | -12.00, -6.02, -2.50, 0.00 dB — gains 0.2512, 0.5000, 0.7499, 1.0 |

Effect byte 1 is tone portamento: change the pitch, keep playing from where the
voice is. Anything else restarts the sample from the beginning.

Playback rate comes from a 96-entry table built as
`f[0] = 1378.125`, `f[i+1] = f[i] * 1.05946309436`, rounded to integers as it
goes, indexed by `(octave + 3) * 12 + (note - 1)`. The instruments are
synthesised at 44100 Hz, so C-5 — index 60 — plays back at exactly one sample
byte per output sample. *Frogzilla uses neither note 0 with a volume set nor
note 15, so the volume-only and note-cut paths are dead in this module.*

## The instruments

`samples.inc` holds eight 16-byte parameter blocks:

```
+0  wavetype (b)   +1  nSamples (w)   +3  freqIni (w)   +5  dFreq (w)
+7  ddFreq (w)     +9  ampIni (b)    +10  dAmp (b)     +11  cutIni (b)
+12 dCut (b)      +13  resIni (b)    +14  dRes (b)     +15  randGain (b)
```

The buffer is `nSamples * 16` bytes long. Per sample:

```
phase += fVal
val    = 2 * (int16)phase / 65536                  wavetype 0: saw
val    = sin(phase * 2*pi/44100)                   wavetype 1 and 2
val    = (val > 0) ? 1 : -1                        wavetype 2 only
val   += randGain * rand() / 127

lfb    = q + q/(1 - f)
buf0  += f * (val - buf0 + lfb*(buf0 - buf1))      resonant low-pass
buf1  += f * (buf0 - buf1)
out    = clamp(buf1 * amp * 127, -127, 127) + 127  unsigned 8-bit

f     += dcut ;  q += dres ;  fVal *= fdVal ;  amp += damp
```

with

```
fVal  = freqIni            fdVal = 1 + dFreq/16777216
f     = cutIni * 85/44100  dcut  = dCut * 85/44100 / nSamples
q     = resIni / 100       dres  = dRes / 100 / nSamples
amp   = dAmp / 100         damp  = ampIni / (100 * nSamples)
```

That last pair is not a typo. The original unpacks its parameters by pushing
six values onto the x87 stack and popping them in reverse, and the two
amplitude terms come off in the opposite order to the C comment in the same
file: `amp` gets `dAmp/100` and `damp` gets `ampIni/(100*nSamples)`. Since
`dAmp` is negative and `ampIni` positive, the envelope runs from about -1 up to
0 instead of from +1 down to 0 — the same decay, phase-inverted. Reproduce it,
or the instruments will not match.

`ddFreq` is parsed and never used.
