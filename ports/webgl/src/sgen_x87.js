// ---------------------------------------------------------------------------
//  Instrument synthesis in emulated x87 extended precision.
//
//  This is not what the intro runs - sgen.js is, in plain doubles, 110 times
//  faster.  This file is the evidence that the two agree: `make audio` runs
//  both and compares them with each other and with the macOS port's output,
//  which is what real x87 hardware produced.  See sgen.js for why doubles are
//  enough here when they were not for looking-for-the-east.
//
//  A port of ../macos-x86_64/src/sgen.inc, which is itself a port of the
//  original sgen_perxxor.asm.
//
//  Eight instruments, each an oscillator (saw, sine, or square) plus white
//  noise, through a resonant low-pass whose cutoff and resonance sweep over the
//  length of the sample, written out as unsigned 8-bit at 44100 Hz.
//
//  Only phase and the two filter taps live in x87 registers; the other nine
//  state variables are stored back to `dd` slots every sample, so they are
//  rounded to 32-bit floats each time round the loop.  Both halves of that
//  matter, so both are reproduced: extended precision through x87.js, and
//  toFloat32 at each store.
//
//  A parameter block is sixteen bytes:
//    +0  wavetype (b)   +1  nSamples (w)  +3  freqIni (w)  +5  dFreq (w)
//    +7  ddFreq (w)     +9  ampIni (b)   +10  dAmp (b)    +11  cutIni (b)
//   +12  dCut (b)      +13  resIni (b)   +14  dRes (b)    +15  randGain (b)
//  ddFreq is read by the original and never used.
// ---------------------------------------------------------------------------

import * as f from './x87.js';
import { samples } from './data.js';

import { NSAMPLES, SAMPLE_STRIDE, sampleBytes } from './sgen.js';

// The state the PRNG shares with the visuals; zero here, as it is when the
// original generates its instruments.
const rnd = { holdrand: 0 };

// The original's myRandFloat: Microsoft's LCG, its low sixteen bits read
// signed, over 32767 - so [-1, 1).
function myRandFloat() {
  rnd.holdrand = (Math.imul(rnd.holdrand, 214013) + 2531011) | 0;
  return f.div(f.fromNumber((rnd.holdrand << 16) >> 16), K32767);
}

const K100 = f.fromNumber(100);
const K127 = f.fromNumber(127);
const K32767 = f.fromNumber(32767);
const K_INV16M = f.fromNumber(Math.fround(0.00000095367431640625));
const K_CUT = f.fromNumber(Math.fround(0.0019274376417233560090702947845805));
const K_2PI44100 = f.fromNumber(Math.fround(1.4247585730565955729989312395825e-4));
const K_2_65 = f.fromNumber(Math.fround(0.000030517578125));
const ONE = f.fromNumber(1);

const s16 = (lo, hi) => ((lo | (hi << 8)) << 16) >> 16;
const s8 = (b) => (b << 24) >> 24;

export function genSamplesX87() {
  rnd.holdrand = 0;
  const buf = new Uint8Array(NSAMPLES * SAMPLE_STRIDE);
  for (let i = 0; i < NSAMPLES; i++) gensample(buf, i);
  return buf;
}

function gensample(buf, i) {
  const b = i * 16;
  const wavetype = samples[b];
  const nBytes = sampleBytes(i);
  const Kn = f.fromNumber(nBytes);

  // Everything in a `dd` slot is a 32-bit float, so every store rounds; F() is
  // that store, kept in register form so the value never leaves x87.js.
  const F = f.roundFloat32;
  let fVal = F(f.fromNumber(s16(samples[b + 3], samples[b + 4])));
  const fdVal = F(f.add(ONE, f.mul(f.fromNumber(s16(samples[b + 5], samples[b + 6])), K_INV16M)));

  // The original pushes six parameters onto the x87 stack and pops them in
  // reverse, and the two amplitude terms come off in the opposite order to the
  // C in the same file: amp gets dAmp/100 and damp gets ampIni/(100*n).  Since
  // dAmp is negative and ampIni positive the envelope runs from about -1 up to
  // 0 rather than from +1 down to 0 - the same decay, phase-inverted.  That is
  // what shipped, and it is what the intro sounds like.
  let amp = F(f.div(f.fromNumber(s8(samples[b + 10])), K100));
  const damp = F(f.div(f.div(f.fromNumber(s8(samples[b + 9])), K100), Kn));
  let ff = F(f.mul(f.fromNumber(samples[b + 11]), K_CUT));       // cutIni, unsigned
  let q = F(f.div(f.fromNumber(s8(samples[b + 13])), K100));
  const dres = F(f.div(f.div(f.fromNumber(s8(samples[b + 14])), K100), Kn));
  const dcut = F(f.div(f.mul(f.fromNumber(s8(samples[b + 12])), K_CUT), Kn));

  const rgain = f.fromNumber(samples[b + 15]);

  let phase = f.ZERO, buf0 = f.ZERO, buf1 = f.ZERO;
  let p = i * SAMPLE_STRIDE;

  for (let n = 0; n < nBytes; n++) {
    phase = f.add(phase, fVal);

    let val;
    if (wavetype === 0) {
      // The saw wraps through a 32-bit store read back as its low word.
      val = f.mul(f.fromNumber((f.toInt32(phase) << 16) >> 16), K_2_65);
    } else {
      val = f.sin(f.mul(phase, K_2PI44100));
      if (wavetype === 2) val = (val.m !== 0n && val.s === 0) ? ONE : f.neg(ONE);
    }
    val = f.add(val, f.div(f.mul(rgain, myRandFloat()), K127));

    // lfb = q + q/(1-f), then the two-pole ladder.
    const lfb = F(f.add(f.div(q, f.sub(ONE, ff)), q));
    buf0 = f.add(buf0, f.mul(f.add(f.sub(val, buf0), f.mul(lfb, f.sub(buf0, buf1))), ff));
    buf1 = f.add(buf1, f.mul(f.sub(buf0, buf1), ff));

    let out = buf1;
    ff = F(f.add(ff, dcut));
    q = F(f.add(q, dres));
    out = f.mul(out, amp);
    fVal = F(f.mul(fVal, fdVal));
    amp = F(f.add(amp, damp));

    let v = f.toInt32(f.mul(out, K127));
    if (v > 127) v = 127; else if (v < -127) v = -127;
    buf[p++] = v + 127;
  }
}
