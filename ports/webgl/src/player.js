// ---------------------------------------------------------------------------
//  Module playback - a port of ../macos-x86_64/src/player.inc, which is itself
//  that port's replacement for the original's eight DirectSound buffers.
//
//  The whole tune is mixed up front into one 16-bit buffer, and the visuals
//  then take their clock from playback position rather than the other way
//  round.  Mixing is single precision throughout because the original's was:
//  movss/mulss/addss, then a round-to-nearest convert and a saturating pack.
//
//  A channel record in zik.asm is 25 bytes - one instrument byte, twelve note
//  bytes, twelve effect bytes.  A note byte is note | octave<<4 | volume<<6,
//  with note 0 meaning nothing, 15 a note cut, and effect byte 1 meaning tone
//  portamento: change the pitch and keep playing from where the voice is.
// ---------------------------------------------------------------------------

import { orderList, patternList, channelList } from './data.js';
import { SAMPLE_STRIDE, sampleBytes } from './sgen.js';

export const NCHANNELS = 8;
export const ORDERS = 54;
export const ROWS = 12;
export const SND_RATE = 44100;
// Speed 8 at tempo 120 is 2500/120*8 = 166.667 ms a row, which is exactly this.
export const ROW_SAMPLES = 7350;
export const TOTAL_SAMPLES = ORDERS * ROWS * ROW_SAMPLES;

const fr = Math.fround;

// DirectSound volumes are hundredths of a decibel; -1200, -602, -250 and 0,
// as linear gain.
const volgain = [0.25118864, 0.50003457, 0.74989421, 1.0].map(fr);
const MASTERGAIN = fr(56.0);
const RATE_F = fr(44100.0);

// f[0] = 1378.125, each entry a semitone above the last, stored as an integer
// as it goes - so the accumulator keeps extended precision across all 96
// multiplies while the table itself is rounded.  Index 60 is C-5, which comes
// out at the sample rate.
export function noteTable() {
  const t = new Int32Array(96);
  let v = fr(1378.125);
  const step = fr(1.05946309436);
  for (let i = 0; i < 96; i++) {
    t[i] = roundTiesEven(v);
    v = v * step;
  }
  return t;
}

export function renderSong(sampbuf) {
  const pcm = new Int16Array(TOTAL_SAMPLES);
  const freqtable = noteTable();
  const len = new Int32Array(8);
  for (let i = 0; i < 8; i++) len[i] = sampleBytes(i);

  // A voice is sample index (-1 idle), position in bytes, step, gain.
  const vSample = new Int32Array(NCHANNELS).fill(-1);
  const vPos = new Float32Array(NCHANNELS);
  const vStep = new Float32Array(NCHANNELS);
  const vGain = new Float32Array(NCHANNELS);

  let out = 0;
  for (let order = 0; order < ORDERS; order++) {
    const pat = orderList[order] * 8;
    for (let row = 0; row < ROWS; row++) {
      for (let ch = 0; ch < NCHANNELS; ch++) {
        const c = (patternList[pat + ch] << 24) >> 24;      // 255 = unused
        if (c < 0) continue;
        const base = c * 25;
        const instrument = channelList[base];
        const note = channelList[base + 1 + row];
        if (note === 0) continue;
        const effect = channelList[base + 13 + row];

        const semi = (note & 15) - 1;        // -1 keeps the pitch, 14 cuts
        const gain = volgain[(note >> 6) & 3];
        if (semi === 14) {
          vSample[ch] = -1; vPos[ch] = 0; vGain[ch] = 0;
        } else if (semi === -1) {
          vGain[ch] = gain;
        } else {
          const idx = (((note >> 4) & 3) + 3) * 12 + semi;   // base octave 3
          vSample[ch] = instrument;
          vStep[ch] = fr(fr(freqtable[idx]) / RATE_F);
          vGain[ch] = gain;
          if (effect !== 1) vPos[ch] = 0;                    // not portamento
        }
      }

      for (let s = 0; s < ROW_SAMPLES; s++) {
        let acc = 0;
        for (let ch = 0; ch < NCHANNELS; ch++) {
          const idx = vSample[ch];
          if (idx < 0) continue;
          const pos = Math.trunc(vPos[ch]);                  // cvttss2si
          if (pos >= len[idx]) { vSample[ch] = -1; continue; }
          const v = sampbuf[idx * SAMPLE_STRIDE + pos] - 127;
          acc = fr(acc + fr(fr(v) * vGain[ch]));
          vPos[ch] = fr(vPos[ch] + vStep[ch]);
        }
        pcm[out++] = packss(roundTiesEven(fr(acc * MASTERGAIN)));
      }
    }
  }
  return pcm;
}

// cvtps2dq: convert with the current rounding mode, which finit leaves at
// round-to-nearest-even.
function roundTiesEven(x) {
  const r = Math.round(x);
  return (r - x === 0.5 && (r & 1)) ? r - 1 : r;
}

function packss(n) {
  return n > 32767 ? 32767 : n < -32768 ? -32768 : n;
}
