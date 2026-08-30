// ---------------------------------------------------------------------------
//  The city, the frog, the glow and the credits - a port of
//  ../macos-x86_64/src/draw.inc, which is a port of the original's
//  drawBlock.asm, drawMultiBlock.asm, drawVehicle.asm, drawMultiVehicle.asm,
//  drawFanal.asm, drawQuad.inc, animateFreddy.inc and timeCalc.asm.
//
//  Every value the original hands to OpenGL, or keeps in one of its globals,
//  goes through a `dd` slot, so it is rounded to single precision at that
//  point.  fr() marks each of those; the arithmetic in between is done in
//  doubles, which are wider than the x87 registers the original used and round
//  to the same float.
// ---------------------------------------------------------------------------

import { GL } from './glfixed.js';
import { glyphs } from './glyphs.js';

const fr = Math.fround;

export const CITY_WIDTH = 9;
export const CITY_HEIGHT = 9;
export const CANTONADES = 2;
export const CAR_NUM = 3;
export const R2T_SIZE = 256;

// The original's globals.
export const st = {
  ts: 0, holdrand: 0, dacamera: 0,
  destruct: 0, height: 0, tmpd2: 0,
  delta: 0, doffset: 0, dtime0: 0, dtime1: 0, carrotate: 0, ncars: 0,
  FreddyPos: 0, FreddyAlt: 0,
  caroffsets: new Float32Array(CAR_NUM * 4),
};

// -- the palette, as glColor4ubv sees it ------------------------------------
export const pal = new Uint8Array([
  0, 0, 0, 0,                     // zerov
  255, 255, 255, 64,
  0, 200, 0, 128,
  204, 204, 204, 0,               // fanal        12
  51, 51, 64, 0,                  // colorBlock   16
  51, 25, 25, 0,                  // clGlass      20
  170, 0, 0, 64,                  // carColors    24
  200, 200, 0, 64,
  0, 145, 64, 64,
  120, 100, 120, 64,
  20, 0, 100, 64,
  200, 100, 0, 64,
  80, 100, 150, 64,
  90, 150, 64, 64,
  80, 80, 80, 0,                  // edifCol      56
  40, 40, 40, 0,
  255, 255, 255, 255,             // onev         64
  128, 255, 51, 255,              // fontcolor    68
]);
export const ZEROV = 0, FANAL = 12, COLORBLOCK = 16, CLGLASS = 20;
export const CARCOLORS = 24, EDIFCOL = 56, ONEV = 64, FONTCOLOR = 68;

// -- the frog: nine spheres, each placed relative to the one before ---------
const ranapx = [0.0, -0.189, 0.00, 0.414, 0.0, 0.045, 0.00, 0.081, 0.00].map(fr);
const ranapy = [-0.09, -0.18, 0.00, 0.00, 0.00, 0.378, 0.00, 0.00, 0.00].map(fr);
const ranapz = [0.0, 0.18, -0.36, 0.36, -0.36, 0.342, -0.324, 0.306, -0.288].map(fr);
const ranarad = [0.315, 0.225, 0.225, 0.1215, 0.1215, 0.1332, 0.099, 0.063, 0.045].map(fr);
const ranarc = [2, 2, 2, 2, 2, 1, 1, 0, 0];

// -- the credits ------------------------------------------------------------
export const textos = 'FUZZIONFROGZILLABPUFIXPAINWONDER';
export const textoffset = [0, 7, 16, 18, 22, 26, 32];
const texxpos = [-2.0, -2.6, -6.0, -4.0, -1.0, 2.0].map(fr);
const texypos = [-0.3, 0.0, -3.0, -3.0, -3.0, -3.0].map(fr);
// The third column is a z offset, not a size.  8.5 rather than the original's
// 9.5, as in the macOS port: at 9.5 the last A of FROGZILLA and its halo fall
// off the right of a 4:3 frustum.
const texsize = [-1.0, 8.5, 2.0, 2.0, 2.0, 2.0].map(fr);

// -- the unit cube: six faces, each a normal then four corners --------------
const cubeverts = new Float32Array([
   0, 0,-1,  -1,-1,-1,   1,-1,-1,   1, 1,-1,  -1, 1,-1,
   1, 0, 0,   1,-1,-1,   1, 1,-1,   1, 1, 1,   1,-1, 1,
  -1, 0, 0,  -1,-1,-1,  -1, 1,-1,  -1, 1, 1,  -1,-1, 1,
   0, 0, 1,  -1,-1, 1,   1,-1, 1,   1, 1, 1,  -1, 1, 1,
   0,-1, 0,  -1,-1,-1,  -1,-1, 1,   1,-1, 1,   1,-1,-1,
   0, 1, 0,  -1, 1,-1,  -1, 1, 1,   1, 1, 1,   1, 1,-1,
]);

// ---------------------------------------------------------------------------
//  The small maths the whole intro rests on.
// ---------------------------------------------------------------------------

// rand() in [-1, 1): Microsoft's LCG, low sixteen bits read signed, over 32767.
export function myRandFloat() {
  st.holdrand = (Math.imul(st.holdrand, 214013) + 2531011) | 0;
  return ((st.holdrand << 16) >> 16) / 32767;
}

// fistp: round to nearest even.
export function fist(x) {
  const r = Math.round(x);
  return (r - x === 0.5 && (r & 1)) ? r - 1 : r;
}

export const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);

// ---------------------------------------------------------------------------
//  The unit cube, translated and scaled.  In the original this was three entry
//  points into one routine, reached by popping the return address around the
//  argument block; only drawCubeTS is ever called.
// ---------------------------------------------------------------------------
// glfixed.js draws this one directly rather than through glBegin/glVertex3f.
// It is the same push, translate, scale, six quads with a normal each, pop -
// and the same numbers - but it is nine tenths of every frame's geometry, and
// the per-vertex call overhead was the single most expensive thing in the
// intro.  g.cubeSlow() is the literal version, kept beside it in glfixed.js.
export function cubeTS(g, tx, ty, tz, sx, sy, sz) {
  g.cube(cubeverts, tx, ty, tz, sx, sy, sz);
}

// ---------------------------------------------------------------------------
//  gluSphere, as GLU draws it: a triangle fan at each pole and a quad strip
//  per band, with per-vertex normals and no texture coordinates.  The frog is
//  nine of these, and the original never pushes the matrix between them - so
//  each translation is relative to the one before, which is how the frog is
//  put together.
// ---------------------------------------------------------------------------
export function gluSphere(g, radius, slices, stacks) {
  const drho = Math.PI / stacks, dtheta = 2 * Math.PI / slices;

  g.begin(GL.TRIANGLE_FAN);
  g.normal3f(0, 0, 1);
  g.vertex3f(0, 0, radius);
  for (let j = 0; j <= slices; j++) {
    const theta = j === slices ? 0 : j * dtheta;
    const x = -Math.sin(theta) * Math.sin(drho);
    const y = Math.cos(theta) * Math.sin(drho);
    const z = Math.cos(drho);
    g.normal3f(x, y, z);
    g.vertex3f(x * radius, y * radius, z * radius);
  }
  g.end();

  for (let i = 1; i < stacks - 1; i++) {
    const rho = i * drho;
    g.begin(GL.QUAD_STRIP);
    for (let j = 0; j <= slices; j++) {
      const theta = j === slices ? 0 : j * dtheta;
      let x = -Math.sin(theta) * Math.sin(rho);
      let y = Math.cos(theta) * Math.sin(rho);
      let z = Math.cos(rho);
      g.normal3f(x, y, z);
      g.vertex3f(x * radius, y * radius, z * radius);
      x = -Math.sin(theta) * Math.sin(rho + drho);
      y = Math.cos(theta) * Math.sin(rho + drho);
      z = Math.cos(rho + drho);
      g.normal3f(x, y, z);
      g.vertex3f(x * radius, y * radius, z * radius);
    }
    g.end();
  }

  g.begin(GL.TRIANGLE_FAN);
  g.normal3f(0, 0, -1);
  g.vertex3f(0, 0, -radius);
  const rho = Math.PI - drho;
  for (let j = slices; j >= 0; j--) {
    const theta = j === slices ? 0 : j * dtheta;
    const x = -Math.sin(theta) * Math.sin(rho);
    const y = Math.cos(theta) * Math.sin(rho);
    const z = Math.cos(rho);
    g.normal3f(x, y, z);
    g.vertex3f(x * radius, y * radius, z * radius);
  }
  g.end();
}

export function drawFrog(g) {
  for (let i = 0; i < 9; i++) {
    g.translatef(ranapx[i], ranapy[i], ranapz[i]);
    g.color4ubv(pal, ranarc[i] * 4);
    gluSphere(g, ranarad[i], 20, 20);
  }
}

// ---------------------------------------------------------------------------
//  A street lamp: a grey post with a white bulb on top.
// ---------------------------------------------------------------------------
export function drawFanal(g) {
  g.color4ubv(pal, FANAL);
  cubeTS(g, 0, fr(0.02), 0, fr(0.0012), fr(0.02), fr(0.0012));
  g.color4ubv(pal, ONEV);
  cubeTS(g, 0, fr(0.04), 0, fr(0.003), fr(0.003), fr(0.003));
}

// ---------------------------------------------------------------------------
//  One city block: a pavement, four sets of three lamps around it, and a tower
//  of st.height floors.  As the destruction front passes, the lamps tip over
//  and the floors rotate off their footings.
// ---------------------------------------------------------------------------
export function drawBlock(g) {
  g.color4ubv(pal, COLORBLOCK);
  cubeTS(g, 0, 0, 0, fr(0.0715), fr(0.002), fr(0.065));

  st.tmpd2 = fr(clamp((st.destruct - st.height) * 8, 0, 30));

  for (let side = 0; side < 4; side++) {
    g.rotatef(90, 0, 1, 0);
    g.pushMatrix();
    g.translatef(fr(0.03), 0, fr(0.06));
    for (let lamp = 0; lamp <= 2; lamp++) {
      g.rotatef(st.tmpd2, 1, 0, 0);
      drawFanal(g);
      // The lean and the step both accumulate, exactly as in the original.
      g.translatef(fr(-0.03), 0, 0);
    }
    g.popMatrix();
  }

  for (let i = 0; i < st.height; i++) {
    g.pushMatrix();
    st.tmpd2 = fr(clamp((st.destruct + i - st.height) * 18, 0, 67));
    g.rotatef(i * 90, 0, 1, 0);
    g.rotatef(st.tmpd2, 1, 0, 0);
    g.translatef(0, fr(fr(i * fr(0.05)) + fr(0.02)), 0);

    g.color4ubv(pal, EDIFCOL);
    cubeTS(g, 0, 0, 0, fr(0.055), fr(0.02), fr(0.055));
    g.color4ubv(pal, EDIFCOL + 4);
    cubeTS(g, 0, fr(0.02), 0, fr(0.05), fr(0.01), fr(0.05));

    for (let face = 0; face < 4; face++) {
      g.rotatef(90, 0, 1, 0);
      for (let w = 0; w <= 4; w++) {
        // Lit only if the noise says so and this floor has not begun to fall.
        const r = myRandFloat();
        g.color4ubv(pal, (r > 0 && !(st.tmpd2 > 0)) ? ONEV : ZEROV);
        cubeTS(g, fr(0.055), 0, fr((w - 2) * fr(0.018)),
               fr(0.001), fr(0.007), fr(0.007));
      }
    }
    g.popMatrix();
  }
}

// ---------------------------------------------------------------------------
//  The city: a ground plane and a 9x9 grid of blocks.  Every block's height
//  comes out of the PRNG the whole frame shares, so the skyline is stable from
//  frame to frame; only the middle three rows are ever demolished.
// ---------------------------------------------------------------------------
export function drawMultiBlock(g) {
  cubeTS(g, 0, fr(-0.008), 0, fr(2.0), fr(0.004), fr(1.2));

  for (let i = 0; i < CITY_HEIGHT; i++) {
    for (let j = 0; j < CITY_WIDTH; j++) {
      g.pushMatrix();
      g.translatef(fr((i - (CITY_HEIGHT >> 1)) * fr(0.24)), 0,
                   fr((j - (CITY_WIDTH >> 1)) * fr(0.24)));

      st.destruct = fr(fr((st.ts - 3100) * fr(0.05)) - (i * 5 + 11));
      const d = Math.abs(j - (CITY_WIDTH >> 1));
      if ((d & 254) !== 0) st.destruct = 0;

      st.height = fist(Math.abs(myRandFloat()) * 7 + 1);
      drawBlock(g);
      g.popMatrix();
    }
  }
}

// ---------------------------------------------------------------------------
//  One car: eight stacked boxes, in one of eight colours.
// ---------------------------------------------------------------------------
export function drawVehicle(g, colour) {
  g.color4ubv(pal, CARCOLORS + (colour & 7) * 4);
  cubeTS(g, 0, 0, 0, fr(0.0061), fr(0.0025), fr(0.01));
  cubeTS(g, 0, fr(0.0057), fr(-0.002), fr(0.0061), fr(0.0003), fr(0.004));
  g.rotatef(fr(-28.65), 1, 0, 0);
  cubeTS(g, 0, fr(-0.0048), fr(0.0088), fr(0.0061), fr(0.0022), fr(0.0012));
  g.color4ubv(pal, CLGLASS);
  g.rotatef(fr(-22.92), 1, 0, 0);
  cubeTS(g, 0, fr(-0.0006), fr(0.0025), fr(0.006), fr(0.0024), fr(0.003));
  g.rotatef(fr(51.57), 1, 0, 0);
  cubeTS(g, 0, fr(0.004), fr(-0.002), fr(0.006), fr(0.0015), fr(0.004));
  g.color4ubv(pal, ONEV);                                     // the headlights
  cubeTS(g, fr(0.003), 0, fr(0.01), fr(0.0015), fr(0.0015), fr(0.0015));
  cubeTS(g, fr(-0.003), 0, fr(0.01), fr(0.0015), fr(0.0015), fr(0.0015));
}

// ---------------------------------------------------------------------------
//  The traffic.  Every intersection seeds the PRNG from its own coordinates
//  and the current lap, which is what puts the cars in the same places every
//  run and slides them along as dtime0 advances.
// ---------------------------------------------------------------------------
export function drawMultiVehicle(g) {
  for (let xc = 0; xc < CITY_HEIGHT; xc++) {
    for (let zc = 0; zc < CITY_WIDTH + CANTONADES; zc++) {
      st.holdrand = fist(st.dtime0 * 2 + zc + xc);
      st.ncars = fist(Math.abs(myRandFloat()) * 4) - 1;

      for (let cedge = 0; cedge < 4; cedge++) {
        g.rotatef(90, 0, 1, 0);
        let cepos = 0;
        do {
          g.pushMatrix();
          const off = st.caroffsets[cepos * 4 + cedge];
          const z = fr(fr((off * 2 - (zc - ((CITY_WIDTH + CANTONADES) >> 1) + 1)) * fr(0.24))
                       + fr((1 - cepos) * fr(0.05)));
          const x = fr(fr(0.1) - fr((xc - ((CITY_HEIGHT + CANTONADES) >> 1) + 1) * fr(0.24)));
          g.translatef(x, 0, z);
          g.rotatef(fr(myRandFloat() * st.carrotate), 0, 1, 0);
          drawVehicle(g, fist(Math.abs(myRandFloat()) * 7));
          g.popMatrix();
          cepos++;
        } while (cepos < st.ncars);
      }
    }
  }
}

// ---------------------------------------------------------------------------
//  timeCalc: where Freddy is, how far the traffic has travelled, and how hard
//  the cars are spinning - all from ts alone.
//
//  The test that was meant to skip the destruction before ts 3100 is a `jl`
//  after an FCOMIP, which clears SF and OF, so it never branches: the
//  destruction arithmetic always runs.  Before ts 3100 it puts Freddy far off
//  in the distance where no camera is looking, so it does not show.
// ---------------------------------------------------------------------------
export function timeCalc() {
  st.delta = fr((st.ts - 3100) / 100);
  const d = st.delta;

  const r = fist(d - fr(0.5));                         // a hop per unit of delta
  st.FreddyPos = fr((r + clamp((d - r) * 2, 0, 1) - 8) * fr(0.24));
  st.FreddyAlt = fr(clamp(Math.sin(d * 2 * Math.PI) * fr(0.4), 0, 1000));

  st.carrotate = fr(clamp((st.ts - 2850 + 20) * fr(1.5), 0, 30));
  st.doffset = fr(clamp(st.ts, 0, 2850));              // traffic freezes at 2850

  const lap = fr(st.doffset * fr(0.0015));
  st.dtime0 = fist(lap - fr(0.5));                     // whole laps ...
  st.dtime1 = fr(lap - st.dtime0);                     // ... and this one's part

  let t = 0;
  for (let cepos = 0; cepos < CAR_NUM; cepos++) {
    for (let cedge = 0; cedge < 4; cedge++) {
      let off = fr(st.dtime1 - fr(cepos * fr(0.0375)));
      if ((cedge & 1) === 0) off = fr(off - fr(0.5));
      st.doffset = off;
      st.caroffsets[t++] = fr(clamp(off / fr(0.4), 0, 1));
    }
  }
}

// ---------------------------------------------------------------------------
//  The glow: the 256x256 render-to-texture from pass three, drawn back over
//  the frame six times additively at successively coarser mip levels.  It is
//  the whole look of the intro - everything bright bleeds.
// ---------------------------------------------------------------------------
export function drawGlow(g) {
  g.loadIdentity();
  g.translatef(fr(-0.665), fr(-0.5), fr(-1.2));
  g.enable(GL.TEXTURE_2D);
  g.enable(GL.BLEND);
  g.blendFunc(GL.SRC_ALPHA, GL.ONE);
  for (let i = 0; i < 6; i++) {
    g.texEnvf(GL.TEXTURE_FILTER_CONTROL, GL.TEXTURE_LOD_BIAS, i + 1);
    drawQuad(g);
  }
  g.disable(GL.TEXTURE_2D);
  g.disable(GL.BLEND);
}

// The 4:3 quad the glow is drawn on, its origin at the bottom left.
export function drawQuad(g) {
  const w = fr(1.333);
  g.begin(GL.QUADS);
  g.texCoord2f(0, 0); g.vertex3f(0, 0, 0);
  g.texCoord2f(1, 0); g.vertex3f(w, 0, 0);
  g.texCoord2f(1, 1); g.vertex3f(w, 1, 0);
  g.texCoord2f(0, 1); g.vertex3f(0, 1, 0);
  g.end();
}

// ---------------------------------------------------------------------------
//  The credits.  The glyph outlines were tessellated ahead of time by
//  tools/extract_glyphs.py, through the same CoreText and the same GLU
//  tessellator the macOS port uses at start-up, and go into display lists
//  numbered by character code - so glCallLists here is what it is there.
// ---------------------------------------------------------------------------
export function buildGlyphLists(g) {
  for (const code of new Set([...textos].map(c => c.charCodeAt(0)))) {
    const gl = glyphs[code];
    g.newList(code, GL.COMPILE);
    g.begin(GL.TRIANGLES);
    for (let i = 0; i < gl.t.length; i += 2) g.vertex3f(gl.t[i], gl.t[i + 1], 0);
    g.end();
    g.translatefRec(gl.a, 0, 0);
    g.endList();
  }
}

const textBytes = new Uint8Array([...textos].map(c => c.charCodeAt(0)));

export function drawText(g, first, count) {
  g.disable(GL.DEPTH_TEST);
  for (let i = first; i < first + count; i++) {
    g.pushMatrix();
    g.translatef(texxpos[i], texypos[i], texsize[i]);
    g.callLists(textoffset[i + 1] - textoffset[i], textBytes, textoffset[i]);
    g.popMatrix();
  }
}
