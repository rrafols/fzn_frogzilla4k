// ---------------------------------------------------------------------------
//  Start-up, in the order ../macos-x86_64/src/intro.asm does it.
// ---------------------------------------------------------------------------

import { GL1, GL } from './glfixed.js';
import { buildGlyphLists, R2T_SIZE } from './draw.js';
import { genSamples } from './sgen.js';
import { renderSong, TOTAL_SAMPLES, SND_RATE } from './player.js';

export const RENDER_W = 640;
export const RENDER_H = 480;

export function createGL(canvas) {
  const gl = canvas.getContext('webgl2', {
    alpha: false, antialias: false, depth: false, stencil: false,
    preserveDrawingBuffer: false, powerPreference: 'high-performance',
  });
  if (!gl) throw new Error('WebGL 2 is required');
  const g = new GL1(gl, RENDER_W, RENDER_H);

  // The glow lives in texture object 0, the default texture, which is where
  // the intro leaves it bound.  Clamping is the one place this port
  // deliberately looks better than the original: the glow samples down to four
  // texels across, and under the GL default of GL_REPEAT a bilinear tap at the
  // edge of the screen-filling quad reaches into the opposite edge of the
  // picture - the bright end of a street coming back as a band along the
  // bottom.  The macOS port does the same.
  g.bindTexture(GL.TEXTURE_2D, 0);
  g.texParameteri(GL.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  g.texParameteri(GL.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  g.texParameteri(GL.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  buildGlyphLists(g);
  return g;
}

// Instruments then the mix - about 0.4 s, so it is worth yielding around.
export async function renderAudio(onProgress) {
  onProgress?.('generating instruments');
  await frameTick();
  const sampbuf = genSamples();
  onProgress?.('mixing the tune');
  await frameTick();
  return renderSong(sampbuf);
}

export function audioBuffer(ctx, pcm) {
  const buf = ctx.createBuffer(1, TOTAL_SAMPLES, SND_RATE);
  const ch = buf.getChannelData(0);
  for (let i = 0; i < pcm.length; i++) ch[i] = pcm[i] / 32768;
  return buf;
}

const frameTick = () => new Promise(r => requestAnimationFrame(r));
