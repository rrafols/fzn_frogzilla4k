// ---------------------------------------------------------------------------
//  Instrument synthesis - a port of ../macos-x86_64/src/sgen.inc, which is
//  itself a port of the original sgen_perxxor.asm.
//
//  Eight instruments, each an oscillator (saw, sine, or square) plus white
//  noise, through a resonant low-pass whose cutoff and resonance sweep over the
//  length of the sample, written out as unsigned 8-bit at 44100 Hz.
//
//  The sister port of this one, for `looking for the east`, needs an emulated
//  80-bit x87 to reproduce its instruments, because one of them runs a sine at
//  3.1e12 Hz and a double's ulp there is two radians.  Frogzilla does not, and
//  it is worth saying why: its phase accumulators stay under 3.4e8, where a
//  double still has 6e-8 of headroom, and - the real reason - the generator
//  keeps only phase and the two filter taps in registers.  The other nine state
//  variables go back to `dd` slots every sample, so each one is rounded to a
//  32-bit float once per iteration and the extra precision inside an expression
//  never survives to the next.
//
//  That is a claim about this data, not a theorem, so it is checked rather than
//  asserted: sgen_x87.js is the same generator in emulated extended precision,
//  and `make audio` runs both against the macOS port's output.  All 578,992
//  instrument bytes and all 4,762,800 mixed samples agree, at 110 times the
//  speed - 49 ms instead of 5.4 s, which is the difference between the intro
//  starting at once and it not.
//
//  A parameter block is sixteen bytes:
//    +0  wavetype (b)   +1  nSamples (w)  +3  freqIni (w)  +5  dFreq (w)
//    +7  ddFreq (w)     +9  ampIni (b)   +10  dAmp (b)    +11  cutIni (b)
//   +12  dCut (b)      +13  resIni (b)   +14  dRes (b)    +15  randGain (b)
//  ddFreq is read by the original and never used.
// ---------------------------------------------------------------------------

import { samples } from './data.js';

export const NSAMPLES = 8;
export const SAMPLE_STRIDE = 340000;     // the longest instrument, 21250 * 16

const fr = Math.fround;
const s16 = (lo, hi) => ((lo | (hi << 8)) << 16) >> 16;
const s8 = (b) => (b << 24) >> 24;

const CUT = fr(0.0019274376417233560090702947845805);   // 85/44100
const INV16M = fr(0.00000095367431640625);              // 1/(16*256*256)
const K2PI = fr(1.4247585730565955729989312395825e-4);  // 2*pi/44100
const K265 = fr(0.000030517578125);                     // 2/65536

// The state the PRNG shares with the visuals; zero while the instruments are
// generated, as it is in the original.
const rnd = { holdrand: 0 };

// The original's myRandFloat: Microsoft's LCG, its low sixteen bits read
// signed, over 32767 - so [-1, 1).
//
// The same generator draw.js exports under that name, over `rnd` rather than
// over `st`; two names because tools/pack.py flattens the modules into one
// scope.  Sharing one state object would be faithful too - the original has a
// single holdrand - but nothing reads across: the instruments are generated
// before the first frame, and every frame resets st.holdrand itself.
function genRandFloat() {
  rnd.holdrand = (Math.imul(rnd.holdrand, 214013) + 2531011) | 0;
  return ((rnd.holdrand << 16) >> 16) / 32767;
}

// fist/fistp: round to nearest even, and store x87's integer indefinite on
// overflow.  The saw's phase leaves int32 range for nothing here, but the
// rounding mode is load-bearing at every sample.
//
// Not draw.js's `fist`, which rounds the same way but has no overflow arm -
// its callers are all small.  Two names because tools/pack.py flattens every
// module into one scope, and the two bodies are not interchangeable.
function fistSat(x) {
  let r = Math.round(x);
  if (r - x === 0.5 && (r & 1)) r -= 1;
  return (r > 2147483647 || r < -2147483648 || !isFinite(r)) ? -2147483648 : r;
}

export function sampleBytes(i) {
  const b = i * 16;
  return ((samples[b + 1] | (samples[b + 2] << 8)) & 0xffff) * 16;
}

export function genSamples() {
  rnd.holdrand = 0;
  const buf = new Uint8Array(NSAMPLES * SAMPLE_STRIDE);
  for (let i = 0; i < NSAMPLES; i++) gensample(buf, i);
  return buf;
}

function gensample(buf, i) {
  const b = i * 16;
  const wavetype = samples[b];
  const n = sampleBytes(i);

  let fVal = fr(s16(samples[b + 3], samples[b + 4]));
  const fdVal = fr(1 + s16(samples[b + 5], samples[b + 6]) * INV16M);

  // The original pushes six parameters onto the x87 stack and pops them in
  // reverse, and the two amplitude terms come off in the opposite order to the
  // C in the same file: amp gets dAmp/100 and damp gets ampIni/(100*n).  Since
  // dAmp is negative and ampIni positive the envelope runs from about -1 up to
  // 0 rather than from +1 down to 0 - the same decay, phase-inverted.  That is
  // what shipped, and it is what the intro sounds like.
  let amp = fr(s8(samples[b + 10]) / 100);
  const damp = fr(fr(s8(samples[b + 9]) / 100) / n);
  let f = fr(samples[b + 11] * CUT);                    // cutIni, unsigned
  let q = fr(s8(samples[b + 13]) / 100);
  const dres = fr(fr(s8(samples[b + 14]) / 100) / n);
  const dcut = fr(fr(s8(samples[b + 12]) * CUT) / n);
  const rgain = samples[b + 15];

  let phase = 0, buf0 = 0, buf1 = 0;
  let p = i * SAMPLE_STRIDE;

  for (let k = 0; k < n; k++) {
    phase += fVal;

    let val;
    if (wavetype === 0) {
      // The ramp wraps through a 32-bit store read back as its low word.
      val = ((fistSat(phase) << 16) >> 16) * K265;
    } else {
      val = Math.sin(phase * K2PI);
      if (wavetype === 2) val = val > 0 ? 1 : -1;
    }
    val += rgain * genRandFloat() / 127;

    // lfb = q + q/(1-f), then the two-pole resonant low-pass.
    const lfb = fr(q / (1 - f) + q);
    buf0 += (val - buf0 + lfb * (buf0 - buf1)) * f;
    buf1 += (buf0 - buf1) * f;

    let out = buf1;
    f = fr(f + dcut);
    q = fr(q + dres);
    out *= amp;
    fVal = fr(fVal * fdVal);
    amp = fr(amp + damp);

    let v = fistSat(out * 127);
    if (v > 127) v = 127; else if (v < -127) v = -127;
    buf[p++] = v + 127;
  }
}
