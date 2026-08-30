// ---------------------------------------------------------------------------
//  The clock, the six cameras and the three passes - a port of
//  ../macos-x86_64/src/frame.inc.
//
//  Read this next to the assembly; it is meant to line up with it statement
//  for statement, including the parts that look wrong:
//
//    * the camera is placed from the *previous* frame's dacamera, because the
//      original recomputes it further down, after the camera is already set;
//    * timeCalc runs after the camera too, so camera 5 follows Freddy one
//      frame late;
//    * lighting is never reset per frame, so pass three - the glow source -
//      is drawn unlit and pass two lit, because each pass leaves the state the
//      next one inherits;
//    * the text is drawn in its own colour only on the first pass and in black
//      afterwards, which is why what you see is a halo with a silhouette in it.
//
//  All of it comes out right because glfixed.js keeps the GL state machine
//  rather than flattening it.
// ---------------------------------------------------------------------------

import { GL } from './glfixed.js';
import { camera_table } from './data.js';
import {
  st, pal, ZEROV, ONEV, FONTCOLOR, R2T_SIZE, myRandFloat, fist, clamp, timeCalc,
  drawMultiBlock, drawMultiVehicle, drawFrog, drawGlow, drawText,
} from './draw.js';

const fr = Math.fround;

// ts per millisecond.  The original divided the clock by a "timeDivider" the
// player thread kept rewriting so that ts tracked the module's row counter -
// twelve rows to an order, 99 ticks.  With the tune mixed up front there is no
// thread to measure anything, so ts runs at the rate that loop was converging
// on: 8.25 ticks per 166.667 ms row.
const TS_SCALE = fr(0.0495);

const ASPECT = fr(4 / 3);                 // the original's hard-coded 4:3
const ZNEAR = fr(0.07);

export function drawFrame(g, ms) {
  st.ts = fr(ms * TS_SCALE);

  // The glow texture wants its mip chain rebuilt from every upload.
  g.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
  g.texParameteri(GL.TEXTURE_2D, GL.GENERATE_MIPMAP, 1);

  g.viewport(0, 0, g.width, g.height);
  g.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
  g.setMatrixMode(GL.PROJECTION);
  g.loadIdentity();
  g.perspective(45.0, ASPECT, ZNEAR, 80.0);
  g.setMatrixMode(GL.MODELVIEW);
  g.loadIdentity();

  // ---- camera, from last frame's dacamera --------------------------------
  const dc = st.dacamera;
  if (dc >= 20) {
    const x = (st.ts - 800) - dc * 100;       // a sin(x)/x shudder per change
    g.translatef(0, fr(Math.sin(x) / x / 100), 0);
  }
  if (dc >= 0) {
    if (dc >= 45) return false;
    if (dc < 36) {
      switch (camera_table[dc]) {
        case 0:                               // sliding down onto the city
          g.translatef(0, fr(fr(1.5) - fr(st.ts * fr(0.001))), fr(-1.0));
          g.rotatef(90, 1, 0, 0);
          break;
        case 1:                               // orbit, 50 degrees down
          g.translatef(0, 0, fr(-1.11));
          g.rotatef(50, 1, 0, 0);
          g.rotatef(fr(st.ts * fr(0.3)), 0, 1, 0);
          break;
        case 2:                               // slower orbit, further out
          g.translatef(0, fr(0.3), fr(-1.85));
          g.rotatef(fr(st.ts / 70), 0, 1, 0);
          g.rotatef(40, 1, 0, 0);
          break;
        case 3:                               // in among the buildings
          g.translatef(0, 0, fr(-0.37));
          g.rotatef(30, 1, 0, 0);
          g.rotatef(fr(st.ts * fr(0.3)), 0, 1, 0);
          break;
        case 4:                               // street level, with the traffic
          g.rotatef(25, 1, 0, 0);
          g.translatef(fr(0.84), fr(-0.1),
                       fr(fr(1.5) - fr((st.caroffsets[1] + st.dtime0) * 2 * fr(0.24))));
          break;
        case 5:                               // locked to Freddy
          g.translatef(0, fr(-(st.FreddyAlt + fr(0.2))), fr(-(st.FreddyPos + fr(1.2))));
          g.rotatef(25, 1, 0, 0);
          g.rotatef(-90, 0, 1, 0);
          break;
      }
    }
  }

  // ---- pass three renders the glow source --------------------------------
  g.viewport(0, 0, R2T_SIZE, R2T_SIZE);
  g.enable(GL.NORMALIZE);
  g.enable(GL.LIGHT0);
  g.enable(GL.BLEND);
  g.enable(GL.COLOR_MATERIAL);
  g.blendFunc(GL.SRC_ALPHA, GL.ZERO);

  st.holdrand = 2;
  timeCalc();

  const t = fist(st.ts);                       // 0 titles, 1 city, 2 credits
  const phase = t < 800 ? 0 : t < 4300 ? 1 : 2;
  st.dacamera = fist((st.ts - 800) / 100);

  for (let pass = 3; pass >= 1; pass--) {
    st.holdrand = 2;
    g.color4ubv(pal, ZEROV);
    g.pushMatrix();

    if (phase !== 1) {
      // ---- the titles and the credits ------------------------------------
      if (pass === 3) g.color4ubv(pal, FONTCOLOR);

      // The text flies in from the distance: z is |clamp(ts,4750) - k| * 0.2
      // - 445, with k jumping at ts 2600 so the credits come back for a
      // second run.
      const tsc = Math.min(st.ts, 4750);
      const k = 2600 < tsc ? 2600 : 1165 - 2600;
      const z = fr(fr(Math.abs(tsc - k) * fr(0.2)) - 445);

      g.disable(GL.LIGHTING);
      g.disable(GL.BLEND);
      g.loadIdentity();
      g.translatef(0, 0, z);

      const count = clamp(fist((st.ts - 4700) / 100), 0, 4) + 1;
      const first = fist(st.ts / 4200);
      drawText(g, first, count);
    } else if (pass !== 1) {
      // ---- the city -------------------------------------------------------
      //
      // Pass three and pass two build this from the same matrices, the same
      // PRNG seed and the same palette, so it comes out vertex for vertex the
      // same both times; all that differs is that pass three is unlit and pass
      // two lit.  frame.inc runs it twice because on a 2004 GPU that was the
      // cheaper of the two.  Here every vertex is transformed in JS, so it is
      // built once on pass three - carrying both colours - and pass two is a
      // copy.  glfixed.js's captureBegin has the rest of it.
      st.holdrand = 14;
      g.enable(GL.DEPTH_TEST);

      if (pass === 3) {
        g.captureBegin();
        drawMultiBlock(g);
        drawMultiVehicle(g);

        g.pushMatrix();                        // animateFreddy
        g.translatef(st.FreddyPos, fr(st.FreddyAlt + fr(0.4)), 0);
        drawFrog(g);
        g.popMatrix();
        g.captureEnd();
      }
      g.captureEmit();                         // unlit on pass three, lit on two

      g.enable(GL.LIGHTING);
      g.disable(GL.BLEND);
      g.disable(GL.DEPTH_TEST);
    }

    if (pass === 3) {
      // Grab the frame that was just drawn and make it the glow texture, mip
      // chain and all.  RGB and not RGBA on purpose: the Win32 original asked
      // for a pixel format with no alpha bitplanes, so glReadPixels handed it
      // alpha 1.0 everywhere and its GL_SRC_ALPHA glow blend was plain
      // addition.  Take the real alpha instead and it is squared twice over,
      // which leaves the text roughly right and stops the city glowing at all.
      // frame.inc reads the pixels back and uploads them again; this copies
      // inside the GPU, which is the same bytes - see glfixed.js.
      g.copyTexImageRGB(0, 0, R2T_SIZE, R2T_SIZE);
      g.viewport(0, 0, g.width, g.height);
      g.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    } else if (pass === 2) {
      g.color4ubv(pal, ONEV);
      g.disable(GL.LIGHTING);
      drawGlow(g);
    }
    g.popMatrix();
  }
  return true;
}
