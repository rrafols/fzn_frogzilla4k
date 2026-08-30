// ---------------------------------------------------------------------------
//  The fixed-function OpenGL 1.1 the intro was written against, on WebGL 2.
//
//  WebGL has none of what this intro uses: no glBegin, no matrix stack, no
//  display lists, no lighting, no glPolygonMode, no line width past 1.0, no
//  LINE_SMOOTH or POINT_SMOOTH.  Rather than rewrite the effects around what
//  WebGL does have, this file puts the old pipeline back, so frame.js and
//  draw.js can stay line-for-line transcriptions of the assembly - which
//  matters more than it sounds, because the intro leans on GL state carrying
//  from one effect to the next and from one frame to the next.  Blend mode is
//  never reset per frame, effect 2 inherits effect 1's modelview, and effect 5
//  draws with whatever glPolygonMode drawRubic left behind.  Emulating the
//  state machine gets all of that for free.
//
//  Transform and lighting happen here, on the CPU, in the same order the
//  fixed-function pipeline did them:
//
//    * triangles are handed to the GPU already in clip space, so WebGL's own
//      clipper and perspective-correct interpolation do the rest;
//    * wide lines and points become screen-space quads, which is what the
//      driver did with them - GL rasterises a width-8 line as an 8-pixel-wide
//      rectangle, and a smooth point as a circle - with LINE_SMOOTH and
//      POINT_SMOOTH coverage applied to *alpha only*, as GL does.  That last
//      detail is why the additively blended flares and lines look hard-edged
//      in the original and have to look hard-edged here.
//
//  Vertex counts are tiny, so doing it this way costs nothing and buys
//  exactness.
//
//  Shared with ../../looking-for-the-east/ports/webgl, which is where it comes
//  from.  Frogzilla needs six things that intro did not: a matrix stack, quad
//  and triangle strips and fans, glColor4ubv, GL_NORMALIZE, a viewport that
//  actually changes mid-frame, and mipmaps with a texture LOD bias - which is
//  the entire glow.
// ---------------------------------------------------------------------------

const fr = Math.fround;

// -- enums, matching consts.inc ---------------------------------------------
export const GL = {
  DEPTH_BUFFER_BIT: 0x0100, COLOR_BUFFER_BIT: 0x4000,
  POINTS: 0, LINES: 1, LINE_STRIP: 3, TRIANGLES: 4, TRIANGLE_STRIP: 5,
  TRIANGLE_FAN: 6, QUADS: 7, QUAD_STRIP: 8,
  ZERO: 0, ONE: 1, SRC_ALPHA: 0x0302, ONE_MINUS_SRC_ALPHA: 0x0303, DST_ALPHA: 0x0304,
  FRONT_AND_BACK: 0x0408,
  POINT_SMOOTH: 0x0B10, LINE_SMOOTH: 0x0B20, LIGHTING: 0x0B50,
  COLOR_MATERIAL: 0x0B57, DEPTH_TEST: 0x0B71, BLEND: 0x0BE2, TEXTURE_2D: 0x0DE1,
  LIGHT0: 0x4000, COMPILE: 0x1300, MODELVIEW: 0x1700, PROJECTION: 0x1701,
  LINE: 0x1B01, FILL: 0x1B02,
  NORMALIZE: 0x0BA1, RGB: 0x1907, RGBA: 0x1908,
  TEXTURE_MIN_FILTER: 0x2801, TEXTURE_MAG_FILTER: 0x2800,
  LINEAR: 0x2601, LINEAR_MIPMAP_LINEAR: 0x2703,
  GENERATE_MIPMAP: 0x8191,
  TEXTURE_FILTER_CONTROL: 0x8500, TEXTURE_LOD_BIAS: 0x8501,
};

// ---------------------------------------------------------------------------
//  4x4 matrices, column-major as GL stores them, kept in single precision
//  because that is the only precision GL promises for them.
// ---------------------------------------------------------------------------
function matIdentity(m) {
  m.fill(0); m[0] = m[5] = m[10] = m[15] = 1;
  return m;
}

// dst = a * b
function matMul(dst, a, b) {
  for (let c = 0; c < 4; c++) {
    for (let r = 0; r < 4; r++) {
      let s = 0;
      for (let k = 0; k < 4; k++) s += a[k * 4 + r] * b[c * 4 + k];
      dst[c * 4 + r] = fr(s);
    }
  }
  return dst;
}

// A cube's 90-float table is six faces of (normal, four corners).  Reduce it
// to the distinct corner positions plus, for each of the 24 slots, which one it
// is.  Cached per table, so this runs once.
const cornerCache = new WeakMap();
function cubeCorners(verts) {
  let c = cornerCache.get(verts);
  if (c) return c;
  const pos = [], slot = new Uint8Array(24);
  for (let f = 0; f < 6; f++) {
    for (let v = 0; v < 4; v++) {
      const o = f * 15 + 3 + v * 3;
      const x = fr(verts[o]), y = fr(verts[o + 1]), z = fr(verts[o + 2]);
      let k = -1;
      for (let i = 0; i < pos.length; i += 3)
        if (pos[i] === x && pos[i + 1] === y && pos[i + 2] === z) { k = i / 3; break; }
      if (k < 0) { k = pos.length / 3; pos.push(x, y, z); }
      slot[f * 4 + v] = k;
    }
  }
  if (pos.length !== 24) throw new Error('cube(): expected eight distinct corners');
  c = { pos: Float64Array.from(pos), slot };
  cornerCache.set(verts, c);
  return c;
}

const tmpM = new Float32Array(16);
const tmpN = new Float32Array(16);

export class GL1 {
  constructor(gl, width, height) {
    this.gl = gl;
    this.width = width;
    this.height = height;

    this.projection = matIdentity(new Float32Array(16));
    this.modelview = matIdentity(new Float32Array(16));
    this.matrixMode = GL.MODELVIEW;
    this.normalMatrix = new Float32Array(9);
    this.normalDirty = true;

    this.color = new Float32Array([1, 1, 1, 1]);
    this.normal = new Float32Array([0, 0, 1]);
    this.uv = new Float32Array([0, 0]);

    this.en = {
      [GL.BLEND]: false, [GL.DEPTH_TEST]: false, [GL.LIGHTING]: false,
      [GL.LIGHT0]: false, [GL.COLOR_MATERIAL]: false, [GL.LINE_SMOOTH]: false,
      [GL.POINT_SMOOTH]: false, [GL.TEXTURE_2D]: false, [GL.NORMALIZE]: false,
    };
    this.lightOn = false;                 // mirrors en[GL.LIGHTING]
    this.normalizeOn = false;             // mirrors en[GL.NORMALIZE]
    this.blendSrc = GL.ONE;
    this.blendDst = GL.ZERO;
    this.lineW = 1;
    this.pointS = 1;
    this.polyMode = GL.FILL;
    this.texture = 0;
    this.viewportRect = [0, 0, width, height];
    this.lodBias = 0;
    this.genMipmap = false;
    // depth + a pool of reusable matrices, not an array of fresh ones.
    this.mvStack = { pool: [], depth: 0 };
    this.projStack = { pool: [], depth: 0 };

    // immediate mode
    this.prim = -1;
    this.direct = false;                  // this primitive writes straight into the batch
    this.cornerClip = new Float64Array(8 * 4);   // cube(): the eight corners
    // Vertices since glBegin.  A typed array with its own length rather than
    // a JS array: the city pushes about three quarters of a million vertices
    // through here per frame, and `push` of ten doubles at a time was costing
    // more than the transform above it.  QUAD_STRIP is the longest primitive
    // the intro draws, so this rarely has to grow.
    this.vbuf = new Float64Array(10 * 256);
    this.vn = 0;
    this.lists = new Map();
    this.recording = null;

    // batches
    this.tri = new Buf(10);
    this.sp = new Buf(12);
    this.idx = new Uint32Array(16384);    // the triangle batch is indexed
    this.idxN = 0;

    // Capture: geometry built once and drawn more than once.  See
    // captureBegin() below.  capVtx holds each vertex twice over - once with
    // the colour it has unlit, once with the colour it would have lit - and
    // capIdx the triangles over them.
    this.capturing = false;
    this.capVtx = new Buf(14);
    this.capIdx = new Uint32Array(16384);
    this.capIdxN = 0;
    this.capDirty = false;                // capture changed since last upload
    this.batchCap = false;                // this batch *is* the capture
    this.batchCapLit = false;
    this.batchKind = 0;                   // 0 none, 1 triangles, 2 screen-space
    this.batchState = -1;
    this.serial = 0;

    this.textures = new Map();
    this.debug = false;                   // set to check glGetError per batch
    this.initGPU();
  }

  // -- state ----------------------------------------------------------------

  enable(cap) { this.setEnable(cap, true); }
  disable(cap) { this.setEnable(cap, false); }
  setEnable(cap, v) {
    if (this.en[cap] === v) return;
    // `en` is keyed by GL enum, so reading it is a dictionary lookup.  The
    // vertex path reads these two per vertex, so they get plain fields too.
    if (cap === GL.LIGHTING) this.lightOn = v;
    else if (cap === GL.NORMALIZE) this.normalizeOn = v;
    // Lighting only changes the colours computed here, so it needs no flush.
    if (cap !== GL.LIGHTING && cap !== GL.COLOR_MATERIAL && cap !== GL.LIGHT0) {
      this.flush();
      this.serial++;
    }
    this.en[cap] = v;
  }

  blendFunc(s, d) {
    if (this.blendSrc === s && this.blendDst === d) return;
    this.flush();
    this.serial++;
    this.blendSrc = s; this.blendDst = d;
  }

  lineWidth(w) { if (this.lineW !== w) { this.flush(); this.lineW = w; } }
  pointSize(s) { if (this.pointS !== s) { this.flush(); this.pointS = s; } }
  polygonMode(face, mode) { this.polyMode = mode; }

  color3f(r, g, b) { this.color[0] = fr(r); this.color[1] = fr(g); this.color[2] = fr(b); this.color[3] = 1; }
  color4f(r, g, b, a) { this.color[0] = fr(r); this.color[1] = fr(g); this.color[2] = fr(b); this.color[3] = fr(a); }
  normal3f(x, y, z) { this.normal[0] = fr(x); this.normal[1] = fr(y); this.normal[2] = fr(z); }

  // The intro's palette is bytes, and their alpha is what decides which parts
  // of the picture are allowed to glow, so it has to survive unrounded.
  color4ubv(bytes, off) {
    this.color[0] = bytes[off] / 255; this.color[1] = bytes[off + 1] / 255;
    this.color[2] = bytes[off + 2] / 255; this.color[3] = bytes[off + 3] / 255;
  }
  texCoord2f(u, v) {
    if (this.recording) { this.recording.push([0, u, v]); return; }
    this.uv[0] = fr(u); this.uv[1] = fr(v);
  }

  // Unlike the intro this file was written for, frogzilla changes the viewport
  // inside a frame: the glow source is rendered into a 256x256 corner of the
  // same buffer.  So this has to reach the GPU, not just the software clipper.
  viewport(x, y, w, h) {
    const v = this.viewportRect;
    if (v[0] === x && v[1] === y && v[2] === w && v[3] === h) return;
    this.flush();
    this.serial++;
    this.viewportRect = [x, y, w, h];
  }

  // The glow's six passes are a texture LOD bias, which GLES has no fixed
  // state for; it goes to the shader instead.
  texEnvf(target, pname, value) {
    if (pname !== GL.TEXTURE_LOD_BIAS || this.lodBias === value) return;
    this.flush();
    this.serial++;
    this.lodBias = value;
  }

  // -- matrices -------------------------------------------------------------

  cur() { return this.matrixMode === GL.PROJECTION ? this.projection : this.modelview; }
  touched() { if (this.matrixMode === GL.MODELVIEW) this.normalDirty = true; }

  setMatrixMode(m) { this.matrixMode = m; }
  loadIdentity() { matIdentity(this.cur()); this.touched(); }

  stack() { return this.matrixMode === GL.PROJECTION ? this.projStack : this.mvStack; }

  // The city pushes and pops tens of thousands of times a frame - a cube is
  // push, translate, scale, pop - so the saved matrices come from a pool
  // rather than from a fresh Float32Array each time.
  pushMatrix() {
    const st = this.stack();
    let m = st.depth < st.pool.length ? st.pool[st.depth] : (st.pool[st.depth] = new Float32Array(16));
    m.set(this.cur());
    st.depth++;
  }

  popMatrix() {
    const st = this.stack();
    if (st.depth === 0) return;
    this.cur().set(st.pool[--st.depth]);
    this.touched();
  }

  // glTranslatef and glScalef are glMultMatrixf with a matrix that is mostly
  // zeroes, and the city calls them for every one of its cubes.  These write
  // the result of that multiply directly.
  //
  // The arithmetic is the multiply's, term for term, not an algebraic
  // simplification of it: matMul accumulates in double from a zero and rounds
  // once with fr(), and the columns that come through unchanged are still
  // written as `+ 0` because that is what turns matMul's -0 into +0.  Anything
  // looser would move vertices in the last bit, and tools/check_packed.mjs
  // hashes every one of them.
  translatef(x, y, z) {
    const c = this.cur();
    const tx = fr(x), ty = fr(y), tz = fr(z);
    for (let r = 0; r < 4; r++) {
      c[12 + r] = fr(c[r] * tx + c[4 + r] * ty + c[8 + r] * tz + c[12 + r]);
      c[r] += 0; c[4 + r] += 0; c[8 + r] += 0;
    }
    this.touched();
  }

  scalef(x, y, z) {
    const c = this.cur();
    const sx = fr(x), sy = fr(y), sz = fr(z);
    for (let r = 0; r < 4; r++) {
      c[r] = fr(c[r] * sx + 0);
      c[4 + r] = fr(c[4 + r] * sy + 0);
      c[8 + r] = fr(c[8 + r] * sz + 0);
      c[12 + r] += 0;
    }
    this.touched();
  }

  // glRotatef, built the way the GL spec spells it out.
  rotatef(angle, x, y, z) {
    const len = Math.sqrt(x * x + y * y + z * z);
    if (len === 0) return;
    x /= len; y /= len; z /= len;
    const a = angle * Math.PI / 180;
    const c = Math.cos(a), s = Math.sin(a), t = 1 - c;
    const m = matIdentity(tmpM);
    m[0] = fr(t * x * x + c);     m[4] = fr(t * x * y - s * z); m[8]  = fr(t * x * z + s * y);
    m[1] = fr(t * x * y + s * z); m[5] = fr(t * y * y + c);     m[9]  = fr(t * y * z - s * x);
    m[2] = fr(t * x * z - s * y); m[6] = fr(t * y * z + s * x); m[10] = fr(t * z * z + c);
    const cm = this.cur();
    cm.set(matMul(tmpN, cm, m));
    this.touched();
  }

  // gluPerspective, which is where the intro's 80-degree field of view and its
  // hard-coded 4:3 come from.
  perspective(fovy, aspect, zNear, zFar) {
    const f = 1 / Math.tan(fovy * Math.PI / 360);
    const m = tmpM;
    m.fill(0);
    m[0] = fr(f / aspect);
    m[5] = fr(f);
    m[10] = fr((zFar + zNear) / (zNear - zFar));
    m[11] = -1;
    m[14] = fr(2 * zFar * zNear / (zNear - zFar));
    const c = this.cur();
    c.set(matMul(tmpN, c, m));
    this.touched();
  }

  updateNormalMatrix() {
    // Inverse transpose of the modelview's upper-left 3x3.  Nothing enables
    // GL_NORMALIZE, so the result is used unnormalised - which is exactly why
    // the cube scaled to (1, 8, 1) in effect 3 shades the way it does.
    const m = this.modelview, n = this.normalMatrix;
    const a = m[0], b = m[4], c = m[8];
    const d = m[1], e = m[5], f2 = m[9];
    const g = m[2], h = m[6], i = m[10];
    const A = e * i - f2 * h, B = f2 * g - d * i, C = d * h - e * g;
    let det = a * A + b * B + c * C;
    if (det === 0) det = 1;
    const id = 1 / det;
    // inverse = adj/det; then transpose.  Row-major here: n[row*3+col].
    n[0] = A * id;               n[1] = B * id;               n[2] = C * id;
    n[3] = (c * h - b * i) * id; n[4] = (a * i - c * g) * id; n[5] = (b * g - a * h) * id;
    n[6] = (b * f2 - c * e) * id; n[7] = (c * d - a * f2) * id; n[8] = (a * e - b * d) * id;
    this.normalDirty = false;
  }

  // -- immediate mode -------------------------------------------------------

  begin(mode) {
    if (this.recording) { this.recording.push([2, mode]); return; }
    // glBegin inside a glBegin is GL_INVALID_OPERATION and is ignored.  Effect
    // 2 does exactly that - three glBegin(GL_LINE_STRIP) against one glEnd -
    // so its three strips are really one, joined across the gaps.  Keep it.
    if (this.prim >= 0) return;
    this.prim = mode;
    this.vn = 0;
    // A filled primitive writes its vertices into the batch as they arrive and
    // end() writes the indices - so a vertex is transformed once, stored once,
    // and shared by however many triangles use it.  Going through vbuf and
    // copying each triangle's three vertices out of it again was costing about
    // half the frame.  Nothing between glBegin and glEnd can change the batch
    // state (colour, normal and texture coordinate are per-vertex, not state
    // the GPU sees), so want() can run here rather than per triangle.
    this.direct = this.polyMode === GL.FILL &&
      (mode === GL.QUADS || mode === GL.TRIANGLES || mode === GL.QUAD_STRIP ||
       mode === GL.TRIANGLE_STRIP || mode === GL.TRIANGLE_FAN);
    if (this.direct) {
      if (this.capturing) {
        this.base = this.capVtx.n / 14;
      } else {
        this.want(1);
        this.base = this.tri.n / 10;      // after want(): it may have flushed
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  Capture, for geometry that is drawn more than once a frame.
  //
  //  The city is: pass three renders it at 256x256 as the glow source, pass two
  //  renders it again full size, from the same matrices, the same PRNG seed and
  //  the same palette.  Every vertex therefore lands in exactly the same place
  //  both times.  The only difference is that pass three is unlit and pass two
  //  is lit - which is a multiply and a clamp on each vertex's colour, and
  //  nothing to do with where it is.
  //
  //  So it is built once.  Between captureBegin() and captureEnd() the vertices
  //  go into capVtx instead of the batch, each one carrying its lit colour
  //  alongside its unlit one, and captureEmit() then appends the whole thing to
  //  the batch - taking whichever of the two colours the current glEnable
  //  (GL_LIGHTING) calls for.
  //
  //  What is captured has to be one batch: nothing between begin and end may
  //  touch state the GPU can see (a viewport, a blend mode, a texture), because
  //  the emitted copy is drawn under whatever state is current at emit time.
  //  Colour, normal and texture coordinate are per-vertex and fine.  The check
  //  in captureEnd() holds the port to that.
  // ---------------------------------------------------------------------------
  captureBegin() {
    this.capVtx.reset();
    this.capIdxN = 0;
    this.capturing = true;
    this.capSerial = this.serial;
  }

  captureEnd() {
    this.capturing = false;
    this.capDirty = true;
    if (this.debug && this.serial !== this.capSerial)
      throw new Error('capture spans a state change - it cannot be one batch');
  }

  captureEmit() {
    const n14 = this.capVtx.n;
    if (n14 === 0) return;
    this.want(1);
    // The usual case: the capture is the whole batch, so it can be drawn
    // straight out of the buffer it was built in.  It is uploaded once and
    // drawn twice, through two vertex layouts over the same bytes - one taking
    // the unlit colour, one the lit - so neither the CPU nor the bus sees this
    // geometry a second time.
    if (this.tri.n === 0 && this.idxN === 0) {
      this.batchCap = true;
      this.batchCapLit = this.lightOn;
      return;
    }
    // Otherwise something else is already in this batch, so the capture has to
    // be copied in beside it, at the batch's own stride.
    const t = this.tri;
    const nv = n14 / 14;
    t.room(nv * 10);
    const ta = t.a, cv = this.capVtx.a;
    let n = t.n;
    const base = n / 10;
    const c = this.lightOn ? 10 : 4;
    for (let o = 0; o < n14; o += 14) {
      ta[n] = cv[o]; ta[n + 1] = cv[o + 1]; ta[n + 2] = cv[o + 2]; ta[n + 3] = cv[o + 3];
      ta[n + 4] = cv[o + c]; ta[n + 5] = cv[o + c + 1]; ta[n + 6] = cv[o + c + 2];
      ta[n + 7] = cv[o + 7]; ta[n + 8] = cv[o + 8]; ta[n + 9] = cv[o + 9];
      n += 10;
    }
    t.n = n;
    const k = this.capIdxN;
    this.idxRoom(k);
    const x = this.idx, ci = this.capIdx;
    const m = this.idxN;
    for (let i = 0; i < k; i++) x[m + i] = ci[i] + base;
    this.idxN = m + k;
  }

  // Room for k more captured indices.
  capRoom(k) {
    if (this.capIdxN + k <= this.capIdx.length) return;
    let m = this.capIdx.length * 2;
    while (m < this.capIdxN + k) m *= 2;
    const b = new Uint32Array(m);
    b.set(this.capIdx.subarray(0, this.capIdxN));
    this.capIdx = b;
  }

  // Room for k more indices.  Called once per primitive rather than per index:
  // the city ends up writing about a million of them a frame.
  idxRoom(k) {
    if (this.idxN + k <= this.idx.length) return;
    let m = this.idx.length * 2;
    while (m < this.idxN + k) m *= 2;
    const b = new Uint32Array(m);
    b.set(this.idx.subarray(0, this.idxN));
    this.idx = b;
  }

  indexTri(a, b, c) {
    this.idxRoom(3);
    const x = this.idx;
    let n = this.idxN;
    x[n] = a; x[n + 1] = b; x[n + 2] = c;
    this.idxN = n + 3;
  }

  vertex3f(x, y, z) {
    if (this.recording) { this.recording.push([1, x, y, z]); return; }
    const mv = this.modelview, p = this.projection;
    x = fr(x); y = fr(y); z = fr(z);

    // eye = MV * v
    const ex = mv[0] * x + mv[4] * y + mv[8] * z + mv[12];
    const ey = mv[1] * x + mv[5] * y + mv[9] * z + mv[13];
    const ez = mv[2] * x + mv[6] * y + mv[10] * z + mv[14];
    const ew = mv[3] * x + mv[7] * y + mv[11] * z + mv[15];
    // clip = P * eye
    const cx = p[0] * ex + p[4] * ey + p[8] * ez + p[12] * ew;
    const cy = p[1] * ex + p[5] * ey + p[9] * ez + p[13] * ew;
    const cz = p[2] * ex + p[6] * ey + p[10] * ez + p[14] * ew;
    const cw = p[3] * ex + p[7] * ey + p[11] * ez + p[15] * ew;

    const col = this.color, uv = this.uv;
    let r = col[0], g = col[1], b = col[2];
    const a = col[3];
    // While capturing, the lit colour is worked out even when lighting is off,
    // because the second copy of this geometry will want it.
    const cap = this.capturing;
    let lr = r, lg = g, lb = b;
    if (this.lightOn || cap) {
      if (this.normalDirty) this.updateNormalMatrix();
      const n = this.normalMatrix, nx = this.normal[0], ny = this.normal[1], nz = this.normal[2];
      // Only the eye-space z of the normal matters: LIGHT0's default position
      // is (0, 0, 1, 0), a directional light straight down +Z, already unit
      // length, and nothing in the intro ever calls glLight*.
      let nez = n[6] * nx + n[7] * ny + n[8] * nz;
      // GL_NORMALIZE, which frogzilla enables and the intro this file came
      // from did not.  Every solid in the city is a unit cube under a
      // non-uniform glScalef, so without it nothing would shade at all.
      if (this.normalizeOn) {
        const ex2 = n[0] * nx + n[1] * ny + n[2] * nz;
        const ey2 = n[3] * nx + n[4] * ny + n[5] * nz;
        const len = Math.sqrt(ex2 * ex2 + ey2 * ey2 + nez * nez);
        if (len > 0) nez /= len;
      }
      // emission 0 + ambient(0.2) * C + max(N.L, 0) * diffuse(1) * C
      const k = 0.2 + (nez > 0 ? nez : 0);
      lr = r * k; lg = g * k; lb = b * k;
      if (lr > 1) lr = 1; if (lg > 1) lg = 1; if (lb > 1) lb = 1;
      if (this.lightOn) { r = lr; g = lg; b = lb; }
    }
    if (this.direct) {
      if (cap) {
        const t = this.capVtx;
        t.room(14);
        const ta = t.a, o = t.n;
        ta[o] = cx; ta[o + 1] = cy; ta[o + 2] = cz; ta[o + 3] = cw;
        ta[o + 4] = r; ta[o + 5] = g; ta[o + 6] = b; ta[o + 7] = a;
        ta[o + 8] = uv[0]; ta[o + 9] = uv[1];
        ta[o + 10] = lr; ta[o + 11] = lg; ta[o + 12] = lb; ta[o + 13] = a;
        t.n = o + 14;
      } else {
        const t = this.tri;
        t.room(10);
        const ta = t.a, o = t.n;
        ta[o] = cx; ta[o + 1] = cy; ta[o + 2] = cz; ta[o + 3] = cw;
        ta[o + 4] = r; ta[o + 5] = g; ta[o + 6] = b; ta[o + 7] = a;
        ta[o + 8] = uv[0]; ta[o + 9] = uv[1];
        t.n = o + 10;
      }
      this.vn += 10;
      return;
    }
    // The screen-space paths - wide lines, points, glPolygonMode(GL_LINE) -
    // clip and project in double precision, so they still collect here first.
    if (this.vn + 10 > this.vbuf.length) {
      const b2 = new Float64Array(this.vbuf.length * 2);
      b2.set(this.vbuf);
      this.vbuf = b2;
    }
    const vb = this.vbuf, o = this.vn;
    vb[o] = cx; vb[o + 1] = cy; vb[o + 2] = cz; vb[o + 3] = cw;
    vb[o + 4] = r; vb[o + 5] = g; vb[o + 6] = b; vb[o + 7] = a;
    vb[o + 8] = uv[0]; vb[o + 9] = uv[1];
    this.vn = o + 10;
  }

  end() {
    if (this.recording) { this.recording.push([3]); return; }
    if (this.prim < 0) return;

    // The filled case: the vertices are already in the batch, so all that is
    // left is which of them each triangle uses.  Same triangles, in the same
    // order, with the same winding as the emit* path below.
    if (this.direct) {
      const n = this.vn / 10, k = this.base;
      const cap = this.capturing;
      // Enough for any of the topologies below.
      if (cap) this.capRoom(n * 6); else this.idxRoom(n * 6);
      const x = cap ? this.capIdx : this.idx;
      let m = cap ? this.capIdxN : this.idxN;
      switch (this.prim) {
        case GL.QUADS:
          for (let i = 0; i + 3 < n; i += 4) {
            x[m] = k + i; x[m + 1] = k + i + 1; x[m + 2] = k + i + 2;
            x[m + 3] = k + i; x[m + 4] = k + i + 2; x[m + 5] = k + i + 3;
            m += 6;
          }
          break;
        case GL.QUAD_STRIP:
          for (let i = 0; i + 3 < n; i += 2) {
            x[m] = k + i; x[m + 1] = k + i + 1; x[m + 2] = k + i + 3;
            x[m + 3] = k + i; x[m + 4] = k + i + 3; x[m + 5] = k + i + 2;
            m += 6;
          }
          break;
        case GL.TRIANGLES:
          for (let i = 0; i + 2 < n; i += 3) {
            x[m] = k + i; x[m + 1] = k + i + 1; x[m + 2] = k + i + 2;
            m += 3;
          }
          break;
        case GL.TRIANGLE_STRIP:
          for (let i = 0; i + 2 < n; i++) {
            if (i & 1) { x[m] = k + i + 1; x[m + 1] = k + i; }
            else { x[m] = k + i; x[m + 1] = k + i + 1; }
            x[m + 2] = k + i + 2;
            m += 3;
          }
          break;
        case GL.TRIANGLE_FAN:
          for (let i = 1; i + 1 < n; i++) {
            x[m] = k; x[m + 1] = k + i; x[m + 2] = k + i + 1;
            m += 3;
          }
          break;
      }
      if (cap) this.capIdxN = m; else this.idxN = m;
      this.direct = false;
      this.prim = -1;
      this.vn = 0;
      return;
    }

    const v = this.vbuf, n = this.vn / 10;
    switch (this.prim) {
      case GL.QUADS:
        for (let i = 0; i + 3 < n; i += 4) this.emitQuad(v, i, i + 1, i + 2, i + 3);
        break;
      case GL.LINES:
        for (let i = 0; i + 1 < n; i += 2) this.emitLine(v, i, i + 1);
        break;
      case GL.LINE_STRIP:
        for (let i = 0; i + 1 < n; i++) this.emitLine(v, i, i + 1);
        break;
      case GL.QUAD_STRIP:
        for (let i = 0; i + 3 < n; i += 2) this.emitQuad(v, i, i + 1, i + 3, i + 2);
        break;
      case GL.TRIANGLES:
        for (let i = 0; i + 2 < n; i += 3) this.emitTri(v, i, i + 1, i + 2);
        break;
      case GL.TRIANGLE_STRIP:
        for (let i = 0; i + 2 < n; i++)
          if (i & 1) this.emitTri(v, i + 1, i, i + 2);
          else this.emitTri(v, i, i + 1, i + 2);
        break;
      case GL.TRIANGLE_FAN:
        for (let i = 1; i + 1 < n; i++) this.emitTri(v, 0, i, i + 1);
        break;
      case GL.POINTS:
        for (let i = 0; i < n; i++) this.emitPoint(v, i);
        break;
    }
    this.prim = -1;
    this.vn = 0;
  }

  // ---------------------------------------------------------------------------
  //  glDrawCube: the one shape the city is made of.
  //
  //  Nine tenths of the frame's vertices come from draw.js's cubeTS, and going
  //  through glBegin/glVertex3f/glEnd for them was costing more in call
  //  overhead than in arithmetic.  This is the same six quads with the same
  //  per-face normals, emitted in one go.
  //
  //  It computes the same numbers the general path does, in the same order.
  //  What it does not do is compute them as many times: a cube has 24 vertices
  //  but only 8 distinct corners, and where a corner lands is the same for all
  //  three faces that meet at it, so each is transformed once.  Lighting still
  //  runs per face, because that is what the normal changes with.
  // ---------------------------------------------------------------------------
  cube(verts, tx, ty, tz, sx, sy, sz) {
    if (this.recording || this.prim >= 0 || this.polyMode !== GL.FILL) {
      this.cubeSlow(verts, tx, ty, tz, sx, sy, sz);
      return;
    }
    this.pushMatrix();
    this.translatef(tx, ty, tz);
    this.scalef(sx, sy, sz);

    const mv = this.modelview, p = this.projection;
    const corner = cubeCorners(verts);          // 8 positions, 24 slot indices
    const pos = corner.pos, slot = corner.slot;

    // The eight corners, once each.
    const cc = this.cornerClip;
    for (let i = 0; i < 8; i++) {
      const x = pos[i * 3], y = pos[i * 3 + 1], z = pos[i * 3 + 2];
      const ex = mv[0] * x + mv[4] * y + mv[8] * z + mv[12];
      const ey = mv[1] * x + mv[5] * y + mv[9] * z + mv[13];
      const ez = mv[2] * x + mv[6] * y + mv[10] * z + mv[14];
      const ew = mv[3] * x + mv[7] * y + mv[11] * z + mv[15];
      const o = i * 4;
      cc[o] = p[0] * ex + p[4] * ey + p[8] * ez + p[12] * ew;
      cc[o + 1] = p[1] * ex + p[5] * ey + p[9] * ez + p[13] * ew;
      cc[o + 2] = p[2] * ex + p[6] * ey + p[10] * ez + p[14] * ew;
      cc[o + 3] = p[3] * ex + p[7] * ey + p[11] * ez + p[15] * ew;
    }

    const cap = this.capturing;
    const t = cap ? this.capVtx : this.tri;
    if (!cap) this.want(1);
    t.room(cap ? 336 : 240);
    if (cap) this.capRoom(36);
    const ta = t.a;
    let n = t.n;
    const base = n / (cap ? 14 : 10);
    const col = this.color, uv = this.uv;
    const u0 = uv[0], v0 = uv[1], a = col[3];
    const nm = this.normal;
    const lit = this.lightOn;

    for (let f = 0; f < 6; f++) {
      const q = f * 15;
      const nx = fr(verts[q]), ny = fr(verts[q + 1]), nz = fr(verts[q + 2]);
      let r = col[0], g = col[1], b = col[2];
      let lr = r, lg = g, lb = b;
      if (lit || cap) {
        if (this.normalDirty) this.updateNormalMatrix();
        const nmat = this.normalMatrix;
        let nez = nmat[6] * nx + nmat[7] * ny + nmat[8] * nz;
        if (this.normalizeOn) {
          const e0 = nmat[0] * nx + nmat[1] * ny + nmat[2] * nz;
          const e1 = nmat[3] * nx + nmat[4] * ny + nmat[5] * nz;
          const len = Math.sqrt(e0 * e0 + e1 * e1 + nez * nez);
          if (len > 0) nez /= len;
        }
        const k = 0.2 + (nez > 0 ? nez : 0);
        lr = r * k; lg = g * k; lb = b * k;
        if (lr > 1) lr = 1; if (lg > 1) lg = 1; if (lb > 1) lb = 1;
        if (lit) { r = lr; g = lg; b = lb; }
      }
      for (let v = 0; v < 4; v++) {
        const o = slot[f * 4 + v] * 4;
        ta[n] = cc[o]; ta[n + 1] = cc[o + 1]; ta[n + 2] = cc[o + 2]; ta[n + 3] = cc[o + 3];
        ta[n + 4] = r; ta[n + 5] = g; ta[n + 6] = b; ta[n + 7] = a;
        ta[n + 8] = u0; ta[n + 9] = v0;
        if (cap) {
          ta[n + 10] = lr; ta[n + 11] = lg; ta[n + 12] = lb; ta[n + 13] = a;
          n += 14;
        } else {
          n += 10;
        }
      }
    }
    t.n = n;

    // glNormal3f is state, and the last face's normal is what it is left at.
    nm[0] = fr(verts[75]); nm[1] = fr(verts[76]); nm[2] = fr(verts[77]);

    if (!cap) this.idxRoom(36);           // may reallocate, so before the alias
    const x = cap ? this.capIdx : this.idx;
    let m = cap ? this.capIdxN : this.idxN;
    for (let f = 0; f < 6; f++) {
      const k = base + f * 4;
      x[m] = k; x[m + 1] = k + 1; x[m + 2] = k + 2;
      x[m + 3] = k; x[m + 4] = k + 2; x[m + 5] = k + 3;
      m += 6;
    }
    if (cap) this.capIdxN = m; else this.idxN = m;

    this.popMatrix();
  }

  // The same cube through the ordinary immediate-mode path, for the cases the
  // fast one bows out of - recording a display list, or glPolygonMode(GL_LINE).
  cubeSlow(verts, tx, ty, tz, sx, sy, sz) {
    this.pushMatrix();
    this.translatef(tx, ty, tz);
    this.scalef(sx, sy, sz);
    this.begin(GL.QUADS);
    for (let q = 0; q < 90; q += 15) {
      this.normal3f(verts[q], verts[q + 1], verts[q + 2]);
      for (let v = 3; v < 15; v += 3)
        this.vertex3f(verts[q + v], verts[q + v + 1], verts[q + v + 2]);
    }
    this.end();
    this.popMatrix();
  }

  // -- display lists --------------------------------------------------------

  translatefRec(x, y, z) {
    if (this.recording) { this.recording.push([4, x, y, z]); return; }
    this.translatef(x, y, z);
  }

  newList(id, mode) { this.recording = []; this.listId = id; }
  endList() { this.lists.set(this.listId, this.recording); this.recording = null; }
  callList(id) {
    const ops = this.lists.get(id);
    if (!ops) return;
    for (const o of ops) {
      if (o[0] === 1) this.vertex3f(o[1], o[2], o[3]);
      else if (o[0] === 0) this.texCoord2f(o[1], o[2]);
      else if (o[0] === 2) this.begin(o[1]);
      else if (o[0] === 4) this.translatef(o[1], o[2], o[3]);
      else this.end();
    }
  }

  // glCallLists(n, GL_UNSIGNED_BYTE, s): the credits draw a string by calling
  // the list whose number is each of its bytes, and each glyph's list ends by
  // translating along its own advance.
  callLists(n, bytes, off) {
    for (let i = 0; i < n; i++) this.callList(bytes[off + i]);
  }

  // -- primitive emission ---------------------------------------------------

  emitQuad(v, a, b, c, d) {
    if (this.polyMode === GL.LINE) this.emitPolyLines(v, [a, b, c, d]);
    else { this.emitTri(v, a, b, c); this.emitTri(v, a, c, d); }
  }

  // The hot one: every solid surface in the city arrives here.  One room check
  // and one straight copy for the whole triangle, rather than three.
  // The unshared path, for a primitive that had to be clipped or projected in
  // vbuf first.  Appends its three vertices and indexes them in order.
  emitTri(v, i0, i1, i2) {
    this.want(1);
    const b = this.tri;
    b.room(30);
    const a = b.a;
    const n = b.n, k = n / 10;
    const o0 = i0 * 10, o1 = i1 * 10, o2 = i2 * 10;
    for (let i = 0; i < 10; i++) a[n + i] = v[o0 + i];
    for (let i = 0; i < 10; i++) a[n + 10 + i] = v[o1 + i];
    for (let i = 0; i < 10; i++) a[n + 20 + i] = v[o2 + i];
    b.n = n + 30;
    this.indexTri(k, k + 1, k + 2);
  }

  // A wide line is a screen-space rectangle from p0 to p1, which is what the
  // rasteriser made of it.  Clip against the near plane first: the tall cube in
  // effect 3 runs straight through the eye.
  emitLine(v, i0, i1) {
    const s = clipNear(v, i0 * 10, i1 * 10);
    if (s) this.lineQuad(s[0], s[1]);
  }

  lineQuad(a, b) {
    const p0 = this.toWindow(a), p1 = this.toWindow(b);
    if (!p0 || !p1) return;
    const dx = p1[0] - p0[0], dy = p1[1] - p0[1];
    const len = Math.hypot(dx, dy);
    if (len === 0) return;
    const half = this.lineW / 2;
    const pad = half + 1;                          // room for the coverage ramp
    const nx = -(dy / len) * pad, ny = (dx / len) * pad;
    this.want(2);
    const q = this.sp;
    const sm = this.en[GL.LINE_SMOOTH] ? 1 : 0;
    q.line(p0, a, nx, ny, -pad, half, 0, sm);
    q.line(p0, a, -nx, -ny, pad, half, 0, sm);
    q.line(p1, b, -nx, -ny, pad, half, 0, sm);
    q.line(p0, a, nx, ny, -pad, half, 0, sm);
    q.line(p1, b, -nx, -ny, pad, half, 0, sm);
    q.line(p1, b, nx, ny, -pad, half, 0, sm);
  }

  emitPoint(v, i) {
    const o = i * 10;
    if (v[o + 3] <= 0 || v[o + 2] + v[o + 3] < 0) return;
    const src = v.slice(o, o + 10);
    const p = this.toWindow(src);
    if (!p) return;
    const half = this.pointS / 2, pad = half + 1;
    this.want(2);
    const q = this.sp;
    const sm = this.en[GL.POINT_SMOOTH] ? 1 : 0;
    q.point(p, src, -pad, -pad, half, 1, sm);
    q.point(p, src,  pad, -pad, half, 1, sm);
    q.point(p, src,  pad,  pad, half, 1, sm);
    q.point(p, src, -pad, -pad, half, 1, sm);
    q.point(p, src,  pad,  pad, half, 1, sm);
    q.point(p, src, -pad,  pad, half, 1, sm);
  }

  // glPolygonMode(GL_LINE): the polygon is clipped, then its boundary is drawn
  // as lines.  Only the near plane needs clipping here - clipping against the
  // sides would put an edge along the screen border, which the original does
  // not show.
  emitPolyLines(v, idx) {
    let poly = idx.map(i => v.slice(i * 10, i * 10 + 10));
    poly = clipPolyNear(poly);
    if (poly.length < 2) return;
    for (let i = 0; i < poly.length; i++)
      this.lineQuad(poly[i], poly[(i + 1) % poly.length]);
  }

  toWindow(a) {
    const w = a[3];
    if (!(w > 0)) return null;
    const [vx, vy, vw, vh] = this.viewportRect;
    return [
      (a[0] / w * 0.5 + 0.5) * vw + vx,
      (a[1] / w * 0.5 + 0.5) * vh + vy,
      a[2] / w,
    ];
  }

  // -- batching -------------------------------------------------------------

  // Every state change that the GPU can see bumps a serial, so want() - which
  // runs once per primitive - is an integer compare rather than a rebuild of
  // the state.  Draw order is preserved because any such change flushes first.
  want(kind) {
    // A captured batch is one draw out of its own buffer, so anything arriving
    // after it starts a new batch rather than joining it.
    if (this.batchCap) this.flush();
    if (this.batchKind !== kind || this.batchState !== this.serial) {
      this.flush();
      this.batchKind = kind;
      this.batchState = this.serial;
      this.batchBlendOn = this.en[GL.BLEND];
      this.batchSrc = this.blendSrc;
      this.batchDst = this.blendDst;
      this.batchDepth = this.en[GL.DEPTH_TEST];
      this.batchTex = this.en[GL.TEXTURE_2D] ? this.texture : -1;
      this.batchView = this.viewportRect;
      this.batchBias = this.lodBias;
    }
  }

  // -- the GPU side ---------------------------------------------------------

  initGPU() {
    const gl = this.gl;

    this.progTri = program(gl, VS_TRI, FS_TRI);
    this.progSP = program(gl, VS_SP, FS_SP);
    this.progBlit = program(gl, VS_BLIT, FS_BLIT);
    this.uUseTex = gl.getUniformLocation(this.progTri, 'uUseTex');
    this.uTex = gl.getUniformLocation(this.progTri, 'uTex');
    this.uBias = gl.getUniformLocation(this.progTri, 'uBias');
    this.uSize = gl.getUniformLocation(this.progSP, 'uSize');
    this.uBlitTex = gl.getUniformLocation(this.progBlit, 'uTex');

    this.bufTri = gl.createBuffer();
    this.bufIdx = gl.createBuffer();
    this.vaoTri = gl.createVertexArray();
    gl.bindVertexArray(this.vaoTri);
    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufTri);
    attrib(gl, this.progTri, 'aPos', 4, 10, 0);
    attrib(gl, this.progTri, 'aColor', 4, 10, 4);
    attrib(gl, this.progTri, 'aUV', 2, 10, 8);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);   // the VAO records this
    gl.bindVertexArray(null);

    // The capture is uploaded once and drawn twice.  Its vertices carry both
    // colours - unlit at offset 4, lit at offset 10, each with its own copy of
    // alpha so that either can be read as a vec4 - so the two draws are the
    // same bytes seen through two vertex layouts, and the shader is untouched.
    this.bufCap = gl.createBuffer();
    this.bufCapIdx = gl.createBuffer();
    for (const [name, off] of [['vaoCapUnlit', 4], ['vaoCapLit', 10]]) {
      this[name] = gl.createVertexArray();
      gl.bindVertexArray(this[name]);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.bufCap);
      attrib(gl, this.progTri, 'aPos', 4, 14, 0);
      attrib(gl, this.progTri, 'aColor', 4, 14, off);
      attrib(gl, this.progTri, 'aUV', 2, 14, 8);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufCapIdx);
      gl.bindVertexArray(null);
    }

    this.bufSP = gl.createBuffer();
    this.vaoSP = gl.createVertexArray();
    gl.bindVertexArray(this.vaoSP);
    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufSP);
    attrib(gl, this.progSP, 'aPos', 3, 12, 0);
    attrib(gl, this.progSP, 'aColor', 4, 12, 3);
    attrib(gl, this.progSP, 'aCoord', 2, 12, 7);
    attrib(gl, this.progSP, 'aParam', 3, 12, 9);
    gl.bindVertexArray(null);

    // The intro renders at 640x480 because glLineWidth and glPointSize are in
    // pixels and the look is calibrated to that resolution; the result is
    // scaled up afterwards.  RGBA8 and a 24-bit depth buffer match the
    // reference build's framebuffer object exactly, which matters because
    // effect 3 and effect 4 blend against destination alpha.
    this.fbo = gl.createFramebuffer();
    this.fboTex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.fboTex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, this.width, this.height, 0,
                  gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    this.fboDepth = gl.createRenderbuffer();
    gl.bindRenderbuffer(gl.RENDERBUFFER, this.fboDepth);
    gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, this.width, this.height);
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.fboTex, 0);
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, this.fboDepth);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    // Bound whenever the intro has no texture enabled.  The fragment shader
    // references its sampler statically, so *something* has to be bound; if
    // that something is left over from present() it is this framebuffer's own
    // texture, and the draw becomes a feedback loop that the browser drops.
    this.blankTex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.blankTex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE,
                  new Uint8Array([255, 255, 255, 255]));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    this.quadBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.quadBuf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
      -1, -1, 0, 0,  1, -1, 1, 0,  1, 1, 1, 1,
      -1, -1, 0, 0,  1, 1, 1, 1,  -1, 1, 0, 1]), gl.STATIC_DRAW);
    this.vaoBlit = gl.createVertexArray();
    gl.bindVertexArray(this.vaoBlit);
    attrib(gl, this.progBlit, 'aPos', 2, 4, 0);
    attrib(gl, this.progBlit, 'aUV', 2, 4, 2);
    gl.bindVertexArray(null);

    gl.disable(gl.CULL_FACE);
    gl.disable(gl.DITHER);
    gl.depthFunc(gl.LESS);
  }

  // -- textures -------------------------------------------------------------
  //
  //  The intro leaves the flare in texture object 0, the default texture,
  //  which WebGL does not have; names are mapped to real objects here.

  texObj(name) {
    let t = this.textures.get(name);
    if (!t) {
      t = this.gl.createTexture();
      this.textures.set(name, t);
      this.gl.bindTexture(this.gl.TEXTURE_2D, t);
      this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.NEAREST_MIPMAP_LINEAR);
      this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE);
      this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE);
    }
    return t;
  }

  bindTexture(target, name) {
    if (this.texture === name) return;
    this.flush();
    this.serial++;
    this.texture = name;
  }

  texParameteri(target, pname, value) {
    const gl = this.gl;
    this.flush();
    // GL_GENERATE_MIPMAP is a texture parameter in GL 1.4 and gone in GLES;
    // remember it and rebuild the chain on upload, which is what it means.
    if (pname === GL.GENERATE_MIPMAP) { this.genMipmap = !!value; return; }
    gl.bindTexture(gl.TEXTURE_2D, this.texObj(this.texture));
    gl.texParameteri(gl.TEXTURE_2D, pname, value);
  }

  // What frame.inc spells as glReadPixels(GL_RGB) then glTexImage2D(GL_RGB):
  // make the frame just drawn into the glow texture.  Done as a copy inside
  // the GPU, so nothing has to come back to JS and be sent out again.
  //
  // RGB and not RGBA on purpose - the Win32 original asked for a pixel format
  // with no alpha bitplanes, so glReadPixels handed it alpha 1.0 everywhere and
  // its GL_SRC_ALPHA glow blend was plain addition.  Take the real alpha
  // instead and it is squared twice over, which leaves the text roughly right
  // and makes the city stop glowing entirely.  An RGB destination drops the
  // source's alpha the same way a GL_RGB read did, so this is that, to the bit.
  //
  // Worth knowing if this is ever revisited: while the vertex pipeline still
  // cost ~60 ms a frame this was 6 ms *slower* than the readback, because
  // generateMipmap on a level the GPU has just written is a worse path for
  // ANGLE than one uploaded from memory, and the readback was meanwhile
  // waiting on a GPU that had long since finished.  It only became the faster
  // of the two once the CPU side came down.  Measure before swapping it back.
  copyTexImageRGB(x, y, w, h) {
    const gl = this.gl;
    this.flush();
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    gl.bindTexture(gl.TEXTURE_2D, this.texObj(this.texture));
    // Storage once and copy into it: glCopyTexImage2D would re-specify the
    // level every frame, throwing away the allocation and its mip chain.
    if (this.glowW !== w || this.glowH !== h) {
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, w, h, 0, gl.RGB, gl.UNSIGNED_BYTE, null);
      this.glowW = w; this.glowH = h;
    }
    gl.copyTexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, x, y, w, h);
    if (this.genMipmap) gl.generateMipmap(gl.TEXTURE_2D);
  }

  // -- frame ----------------------------------------------------------------

  beginFrame() {
    const gl = this.gl;
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    gl.disable(gl.SCISSOR_TEST);
  }

  clearColorf(r, g, b, a) { this.clearCol = [r, g, b, a]; }

  clear(mask) {
    const gl = this.gl;
    this.flush();
    const c = this.clearCol || [0, 0, 0, 0];
    gl.clearColor(c[0], c[1], c[2], c[3]);
    gl.colorMask(true, true, true, true);
    gl.depthMask(true);
    gl.clear((mask & GL.COLOR_BUFFER_BIT ? gl.COLOR_BUFFER_BIT : 0) |
             (mask & GL.DEPTH_BUFFER_BIT ? gl.DEPTH_BUFFER_BIT : 0));
  }

  flush() {
    const gl = this.gl;
    const kind = this.batchKind;
    if (kind === 0) return;
    const cap = this.batchCap;
    const buf = kind === 1 ? this.tri : this.sp;
    if (!cap && (buf.n === 0 || (kind === 1 && this.idxN === 0))) {
      buf.reset();
      this.idxN = 0;
      this.batchKind = 0;
      this.batchState = -1;
      return;
    }

    const v = this.batchView;
    gl.viewport(v[0], v[1], v[2], v[3]);
    if (this.batchBlendOn) { gl.enable(gl.BLEND); gl.blendFunc(this.batchSrc, this.batchDst); }
    else gl.disable(gl.BLEND);
    if (this.batchDepth) { gl.enable(gl.DEPTH_TEST); gl.depthMask(true); }
    else { gl.disable(gl.DEPTH_TEST); gl.depthMask(false); }

    if (kind === 1) {
      gl.useProgram(this.progTri);
      if (cap) {
        gl.bindVertexArray(this.batchCapLit ? this.vaoCapLit : this.vaoCapUnlit);
        if (this.capDirty) {
          gl.bindBuffer(gl.ARRAY_BUFFER, this.bufCap);
          gl.bufferData(gl.ARRAY_BUFFER, this.capVtx.a.subarray(0, this.capVtx.n), gl.STREAM_DRAW);
          gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufCapIdx);
          gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.capIdx.subarray(0, this.capIdxN), gl.STREAM_DRAW);
          this.capDirty = false;
        }
      } else {
        gl.bindVertexArray(this.vaoTri);
        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufTri);
        gl.bufferData(gl.ARRAY_BUFFER, buf.a.subarray(0, buf.n), gl.STREAM_DRAW);
      }
      const useTex = this.batchTex >= 0;
      gl.uniform1i(this.uUseTex, useTex ? 1 : 0);
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, useTex ? this.texObj(this.batchTex) : this.blankTex);
      gl.uniform1i(this.uTex, 0);
      gl.uniform1f(this.uBias, this.batchBias);
      if (cap) {
        gl.drawElements(gl.TRIANGLES, this.capIdxN, gl.UNSIGNED_INT, 0);
      } else {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.idx.subarray(0, this.idxN), gl.STREAM_DRAW);
        gl.drawElements(gl.TRIANGLES, this.idxN, gl.UNSIGNED_INT, 0);
      }
    } else {
      gl.useProgram(this.progSP);
      gl.bindVertexArray(this.vaoSP);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.bufSP);
      gl.bufferData(gl.ARRAY_BUFFER, buf.a.subarray(0, buf.n), gl.STREAM_DRAW);
      gl.uniform2f(this.uSize, this.width, this.height);
      gl.drawArrays(gl.TRIANGLES, 0, buf.n / 12);
    }
    if (this.debug) {
      const e = gl.getError();
      if (e) throw new Error('GL error 0x' + e.toString(16) + ' after a ' +
                             (kind === 1 ? 'triangle' : 'screen-space') + ' batch');
    }
    buf.reset();
    this.idxN = 0;
    this.batchCap = false;
    this.batchKind = 0;
    this.batchState = -1;
  }

  // Scale the 640x480 frame into a 4:3 box on the canvas, letterboxed, the way
  // the macOS port blits its corner of the back buffer to the display.
  present(canvasW, canvasH) {
    const gl = this.gl;
    this.flush();
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.viewport(0, 0, canvasW, canvasH);
    gl.disable(gl.BLEND);
    gl.disable(gl.DEPTH_TEST);
    gl.depthMask(false);
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    let w = Math.floor(canvasH * 4 / 3), h = canvasH;
    if (w > canvasW) { w = canvasW; h = Math.floor(canvasW * 3 / 4); }
    gl.viewport((canvasW - w) >> 1, (canvasH - h) >> 1, w, h);

    gl.useProgram(this.progBlit);
    gl.bindVertexArray(this.vaoBlit);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this.fboTex);
    gl.uniform1i(this.uBlitTex, 0);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    gl.bindVertexArray(null);
    gl.bindTexture(gl.TEXTURE_2D, null);      // never leave the target sampled
  }

  // The verification path: the same RGB bytes glReadPixels hands back, bottom
  // row first, so they can go straight into a PPM.
  readPixels() {
    const gl = this.gl;
    this.flush();
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo);
    const rgba = new Uint8Array(this.width * this.height * 4);
    gl.readPixels(0, 0, this.width, this.height, gl.RGBA, gl.UNSIGNED_BYTE, rgba);
    const rgb = new Uint8Array(this.width * this.height * 3);
    for (let i = 0, o = 0; i < rgba.length; i += 4) {
      rgb[o++] = rgba[i]; rgb[o++] = rgba[i + 1]; rgb[o++] = rgba[i + 2];
    }
    return rgb;
  }
}

// ---------------------------------------------------------------------------
//  Shaders.  All the pipeline work has happened by the time anything gets
//  here: the triangle program just passes clip coordinates through, and the
//  screen-space program turns a pixel offset into the coverage the smooth
//  line and point rules ask for.
// ---------------------------------------------------------------------------

const VS_TRI = `#version 300 es
in vec4 aPos; in vec4 aColor; in vec2 aUV;
out vec4 vColor; out vec2 vUV;
void main() { vColor = aColor; vUV = aUV; gl_Position = aPos; }`;

const FS_TRI = `#version 300 es
precision highp float;
in vec4 vColor; in vec2 vUV;
uniform sampler2D uTex; uniform bool uUseTex; uniform float uBias;
out vec4 o;
void main() {
  vec4 c = vColor;
  // GL_MODULATE, the default texture environment.  The bias is what GL 1.4
  // called GL_TEXTURE_LOD_BIAS: the glow draws the same texture six times at
  // rising mip levels, and this is the whole effect.
  if (uUseTex) c *= texture(uTex, vUV, uBias);
  o = c;
}`;

const VS_SP = `#version 300 es
in vec3 aPos; in vec4 aColor; in vec2 aCoord; in vec3 aParam;
uniform vec2 uSize;
out vec4 vColor; out vec2 vCoord; out vec3 vParam;
void main() {
  vColor = aColor; vCoord = aCoord; vParam = aParam;
  gl_Position = vec4(aPos.x / uSize.x * 2.0 - 1.0,
                     aPos.y / uSize.y * 2.0 - 1.0, aPos.z, 1.0);
}`;

const FS_SP = `#version 300 es
precision highp float;
in vec4 vColor; in vec2 vCoord; in vec3 vParam;
out vec4 o;
void main() {
  float halfExtent = vParam.x;
  // lines measure across the segment, points measure radially
  float d = vParam.y < 0.5 ? abs(vCoord.y) : length(vCoord);
  float cov = vParam.z > 0.5 ? clamp(halfExtent + 0.5 - d, 0.0, 1.0)
                             : (d <= halfExtent ? 1.0 : 0.0);
  if (cov <= 0.0) discard;
  // GL applies antialiasing coverage to alpha, not to colour - so a smooth
  // line under GL_ONE/GL_ONE blending has hard edges, and has to keep them.
  o = vec4(vColor.rgb, vColor.a * cov);
}`;

const VS_BLIT = `#version 300 es
in vec2 aPos; in vec2 aUV; out vec2 vUV;
void main() { vUV = aUV; gl_Position = vec4(aPos, 0.0, 1.0); }`;

const FS_BLIT = `#version 300 es
precision highp float;
in vec2 vUV; uniform sampler2D uTex; out vec4 o;
void main() { o = vec4(texture(uTex, vUV).rgb, 1.0); }`;

function shader(gl, type, src) {
  const s = gl.createShader(type);
  gl.shaderSource(s, src);
  gl.compileShader(s);
  if (!gl.getShaderParameter(s, gl.COMPILE_STATUS))
    throw new Error(gl.getShaderInfoLog(s) + '\n' + src);
  return s;
}

function program(gl, vs, fs) {
  const p = gl.createProgram();
  gl.attachShader(p, shader(gl, gl.VERTEX_SHADER, vs));
  gl.attachShader(p, shader(gl, gl.FRAGMENT_SHADER, fs));
  gl.linkProgram(p);
  if (!gl.getProgramParameter(p, gl.LINK_STATUS))
    throw new Error(gl.getProgramInfoLog(p));
  return p;
}

function attrib(gl, prog, name, size, stride, offset) {
  const loc = gl.getAttribLocation(prog, name);
  if (loc < 0) return;
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, size, gl.FLOAT, false, stride * 4, offset * 4);
}

// ---------------------------------------------------------------------------
//  Growable float buffers for the two batch kinds.
// ---------------------------------------------------------------------------
class Buf {
  constructor(stride) {
    this.stride = stride;
    this.a = new Float32Array(stride * 4096);
    this.n = 0;
  }
  room(k) {
    if (this.n + k <= this.a.length) return;
    const b = new Float32Array(Math.max(this.a.length * 2, this.n + k));
    b.set(this.a.subarray(0, this.n));
    this.a = b;
  }
  push10(v, o) {
    this.room(10);
    for (let i = 0; i < 10; i++) this.a[this.n++] = v[o + i];
  }
  // screen-space vertex: x, y, z, rgba, coord.xy, halfExtent, kind, smooth
  line(p, src, ox, oy, d, half, kind, sm) {
    this.room(12);
    const a = this.a;
    a[this.n++] = p[0] + ox; a[this.n++] = p[1] + oy; a[this.n++] = p[2];
    a[this.n++] = src[4]; a[this.n++] = src[5]; a[this.n++] = src[6]; a[this.n++] = src[7];
    a[this.n++] = 0; a[this.n++] = d;
    a[this.n++] = half; a[this.n++] = kind; a[this.n++] = sm;
  }
  point(p, src, ox, oy, half, kind, sm) {
    this.room(12);
    const a = this.a;
    a[this.n++] = p[0] + ox; a[this.n++] = p[1] + oy; a[this.n++] = p[2];
    a[this.n++] = src[4]; a[this.n++] = src[5]; a[this.n++] = src[6]; a[this.n++] = src[7];
    a[this.n++] = ox; a[this.n++] = oy;
    a[this.n++] = half; a[this.n++] = kind; a[this.n++] = sm;
  }
  reset() { this.n = 0; }
}

// ---------------------------------------------------------------------------
//  Near-plane clipping in homogeneous clip space (z + w >= 0).
// ---------------------------------------------------------------------------
const NEAR_EPS = 1e-7;

function clipNear(v, o0, o1) {
  const a = v.slice(o0, o0 + 10), b = v.slice(o1, o1 + 10);
  const da = a[2] + a[3], db = b[2] + b[3];
  if (da >= NEAR_EPS && db >= NEAR_EPS) return [a, b];
  if (da < NEAR_EPS && db < NEAR_EPS) return null;
  const t = da / (da - db);
  const m = lerp10(a, b, t);
  return da >= NEAR_EPS ? [a, m] : [m, b];
}

function clipPolyNear(poly) {
  const out = [];
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    const da = a[2] + a[3], db = b[2] + b[3];
    if (da >= NEAR_EPS) out.push(a);
    if ((da >= NEAR_EPS) !== (db >= NEAR_EPS)) out.push(lerp10(a, b, da / (da - db)));
  }
  return out;
}

function lerp10(a, b, t) {
  const m = new Array(10);
  for (let i = 0; i < 10; i++) m[i] = a[i] + (b[i] - a[i]) * t;
  return m;
}
