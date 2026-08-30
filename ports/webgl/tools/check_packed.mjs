// Runs the minified build and the module build side by side and compares what
// they compute: the eight instruments, the whole mixed tune, the note table,
// and - the interesting one - every vertex the thirteen reference frames send
// to the GPU.  Minifiers are where a port like this would quietly lose its
// arithmetic, so this is checked rather than assumed.
//
//   python3 tools/pack.py --check && node tools/check_packed.mjs
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { genSamples } from '../src/sgen.js';
import { renderSong, noteTable } from '../src/player.js';
import { createGL } from '../src/intro.js';
import { drawFrame } from '../src/frame.js';

const path = fileURLToPath(new URL('../build/frogzilla.check.js', import.meta.url));
const packed = new Function(readFileSync(path, 'utf8') + ';return globalThis.__x')();

// ../macos-x86_64/src/offscreen.inc's shot_ms, as shot.html has them.
const SHOT_MS = [15556, 17172, 21212, 25253, 29293, 49495, 63636,
                 70707, 76768, 81818, 85859, 94949, 104040];

// A WebGL 2 context that does nothing but hand back plausible objects, so
// glfixed.js will build its programs and run its batches without a GPU.  What
// the frames are actually judged on is the float data that reaches
// bufferData - the vertex stream after the modelview, the projection and the
// lighting, which is every number the two builds could disagree about.
function stubGL(onVertices) {
  let n = 0;
  const obj = () => ({ id: ++n });
  const gl = new Proxy({}, {
    get(_, k) {
      if (k === 'getAttribLocation') return () => -1;      // skip attrib setup
      if (k === 'getProgramParameter' || k === 'getShaderParameter') return () => true;
      if (k === 'getProgramInfoLog' || k === 'getShaderInfoLog') return () => '';
      if (k === 'bufferData') return (_t, data) => { if (data?.length) onVertices(data); };
      if (k === 'createProgram' || k === 'createShader' || k === 'createBuffer' ||
          k === 'createVertexArray' || k === 'createTexture' ||
          k === 'createFramebuffer' || k === 'createRenderbuffer' ||
          k === 'getUniformLocation') return obj;
      // Every remaining name is either a call the stub can ignore or an enum;
      // a function that also reads as a distinct number covers both.
      const f = () => {};
      f.valueOf = () => 0x1000 + [...String(k)].reduce((h, c) => h * 31 + c.charCodeAt(0) & 0xffff, 0);
      return f;
    },
  });
  return gl;
}

const dv = new DataView(new ArrayBuffer(4));
const fnv = (feed) => {
  let h = 2166136261 >>> 0;
  feed(b => { h ^= b & 0xff; h = Math.imul(h, 16777619) >>> 0; });
  return h >>> 0;
};
const bytes = a => fnv(p => { for (const v of a) p(v); });
const words = a => fnv(p => { for (const v of a) { p(v); p(v >> 8); } });

// Every frame's vertex stream, hashed as the float32 bits actually uploaded.
function frames(api) {
  let h = 2166136261 >>> 0;
  const feed = (data) => {
    for (const v of data) {
      dv.setFloat32(0, v);
      for (let b = 0; b < 4; b++) { h ^= dv.getUint8(b); h = Math.imul(h, 16777619) >>> 0; }
    }
  };
  const g = api.createGL({ getContext: () => stubGL(feed) });
  // Twice per frame, as shot.html and the macOS offscreen build do: the camera
  // is placed from the previous frame's dacamera.
  for (const ms of SHOT_MS) for (let warm = 0; warm < 2; warm++) api.drawFrame(g, ms);
  return h >>> 0;
}

const build = (api) => {
  const buf = api.genSamples();
  return { buf, pcm: api.renderSong(buf), notes: api.noteTable(), verts: frames(api) };
};

const cases = [
  ['instruments', m => bytes(m.buf)],
  ['mixed tune', m => words(m.pcm)],
  ['note table', m => words(m.notes)],
  ['frame vertices', m => m.verts],
];

const a = build({ genSamples, renderSong, noteTable, createGL, drawFrame });
const b = build(packed);

let bad = 0;
for (const [name, run] of cases) {
  const x = run(a), y = run(b);
  const ok = x === y;
  if (!ok) bad++;
  console.log('  %s %s  %s', ok ? 'ok  ' : 'FAIL', name.padEnd(16),
              ok ? x.toString(16) : x.toString(16) + ' vs ' + y.toString(16));
}
console.log(bad ? '\n%d of %d differ' : '\nminified build is identical (%d of %d differ)',
            bad, cases.length);
process.exit(bad ? 1 : 0);
