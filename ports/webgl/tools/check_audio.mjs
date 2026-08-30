// Renders the tune and compares it with the macOS port's song.wav, which is
// the same mix produced by the same arithmetic on real x87 hardware.
//
// Also runs the emulated-x87 generator (src/sgen_x87.js) against the plain
// double one the intro actually uses, which is what turns "doubles are enough
// for this intro" from a claim into a test.  Skip that with --fast.
//
//   node tools/check_audio.mjs [path/to/song.wav] [--fast]
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { genSamples } from '../src/sgen.js';
import { genSamplesX87 } from '../src/sgen_x87.js';
import { renderSong, TOTAL_SAMPLES } from '../src/player.js';

const args = process.argv.slice(2);
const fast = args.includes('--fast');
const ref = args.find(a => !a.startsWith('--')) ||
  fileURLToPath(new URL('../../macos-x86_64/build/linked/song.wav', import.meta.url));

let t = Date.now();
const sampbuf = genSamples();
console.log('instruments: %d ms', Date.now() - t);
t = Date.now();
const pcm = renderSong(sampbuf);
console.log('mix:         %d ms  (%d samples)', Date.now() - t, pcm.length);

if (!fast) {
  t = Date.now();
  const x87 = genSamplesX87();
  let bad = 0;
  for (let i = 0; i < sampbuf.length; i++) if (sampbuf[i] !== x87[i]) bad++;
  console.log('x87 check:   %d ms  -> %s',
              Date.now() - t,
              bad ? bad + ' of ' + sampbuf.length + ' instrument bytes DIFFER'
                  : 'all ' + sampbuf.length + ' instrument bytes identical');
  if (bad) process.exitCode = 1;
}

let wav;
try { wav = readFileSync(ref); }
catch { console.log('\nno reference at %s - build it with `make verify` in ports/macos-x86_64', ref); process.exit(0); }

const got = pcm;
const want = new Int16Array(wav.buffer, wav.byteOffset + 44, (wav.length - 44) >> 1);
console.log('reference:   %d samples', want.length);

const n = Math.min(got.length, want.length);
let diff = 0, maxAbs = 0, sumAbs = 0, firstAt = -1;
for (let i = 0; i < n; i++) {
  const d = Math.abs(got[i] - want[i]);
  if (d) { diff++; sumAbs += d; if (d > maxAbs) maxAbs = d; if (firstAt < 0) firstAt = i; }
}
console.log('\ndiffering samples: %d / %d (%s%%)', diff, n, (100 * diff / n).toFixed(6));
if (diff) {
  console.log('first at:          %d (%.3f s)', firstAt, firstAt / 44100);
  console.log('max |delta|:       %d of 32768', maxAbs);
  console.log('mean |delta|:      %s (over differing samples)', (sumAbs / diff).toFixed(3));
  for (let i = firstAt; i < Math.min(firstAt + 8, n); i++)
    console.log('  [%d] got %d want %d', i, got[i], want[i]);
} else {
  console.log('identical.');
}
