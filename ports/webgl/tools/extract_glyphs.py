#!/usr/bin/env python3
"""Turn the credits' glyphs into src/glyphs.js.

The Win32 original called wglUseFontOutlinesA, which asked GDI for Arial Bold,
tessellated every glyph at em size 1.0 and compiled the result into a display
list per character code.  The macOS port rebuilds those lists at start-up from
CoreText outlines through the GLU tessellator (src/text.inc); a browser can do
neither, so the same pipeline is run here, once, and the triangles are shipped.

This is the same CoreText and the same GLU tessellator the macOS port uses, so
the geometry is identical - not merely similar.  It therefore only runs on
macOS; the output is generated ahead of time and committed, and the port itself
needs neither.

    python3 tools/extract_glyphs.py
"""
import ctypes, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'src', 'glyphs.js'))

FONT = b'Arial-BoldMT'
TEXT = 'FUZZIONFROGZILLABPUFIXPAINWONDER'     # data.inc's "textos"
STEPS = 8                                      # src/text.inc's FLATTEN_STEPS

F = '/System/Library/Frameworks/%s.framework/%s'
cf = ctypes.CDLL(F % ('CoreFoundation', 'CoreFoundation'))
ct = ctypes.CDLL(F % ('CoreText', 'CoreText'))
cg = ctypes.CDLL(F % ('CoreGraphics', 'CoreGraphics'))
glu = ctypes.CDLL(F % ('OpenGL', 'OpenGL'))

cf.CFStringCreateWithCString.restype = ctypes.c_void_p
cf.CFStringCreateWithCString.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32]
ct.CTFontCreateWithName.restype = ctypes.c_void_p
ct.CTFontCreateWithName.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_void_p]
ct.CTFontGetGlyphsForCharacters.restype = ctypes.c_bool
ct.CTFontGetGlyphsForCharacters.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_uint16),
                                            ctypes.POINTER(ctypes.c_uint16), ctypes.c_long]
ct.CTFontCreatePathForGlyph.restype = ctypes.c_void_p
ct.CTFontCreatePathForGlyph.argtypes = [ctypes.c_void_p, ctypes.c_uint16, ctypes.c_void_p]
ct.CTFontGetAdvancesForGlyphs.restype = ctypes.c_double
ct.CTFontGetAdvancesForGlyphs.argtypes = [ctypes.c_void_p, ctypes.c_uint32,
                                          ctypes.POINTER(ctypes.c_uint16), ctypes.c_void_p,
                                          ctypes.c_long]
APPLIER = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)
cg.CGPathApply.argtypes = [ctypes.c_void_p, ctypes.c_void_p, APPLIER]

for name, res, args in [
        ('gluNewTess', ctypes.c_void_p, []),
        ('gluTessCallback', None, [ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p]),
        ('gluTessProperty', None, [ctypes.c_void_p, ctypes.c_uint, ctypes.c_double]),
        ('gluTessNormal', None, [ctypes.c_void_p, ctypes.c_double, ctypes.c_double, ctypes.c_double]),
        ('gluTessBeginPolygon', None, [ctypes.c_void_p, ctypes.c_void_p]),
        ('gluTessBeginContour', None, [ctypes.c_void_p]),
        ('gluTessVertex', None, [ctypes.c_void_p, ctypes.POINTER(ctypes.c_double), ctypes.c_void_p]),
        ('gluTessEndContour', None, [ctypes.c_void_p]),
        ('gluTessEndPolygon', None, [ctypes.c_void_p])]:
    fn = getattr(glu, name)
    fn.restype, fn.argtypes = res, args

GLU_TESS_BEGIN, GLU_TESS_VERTEX, GLU_TESS_END, GLU_TESS_COMBINE = 100100, 100101, 100102, 100105
GLU_TESS_WINDING_RULE, GLU_TESS_WINDING_NONZERO = 100140, 100131
GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN = 4, 5, 6

CB_BEGIN = ctypes.CFUNCTYPE(None, ctypes.c_uint)
CB_VERTEX = ctypes.CFUNCTYPE(None, ctypes.c_void_p)
CB_END = ctypes.CFUNCTYPE(None)
CB_COMBINE = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_double), ctypes.c_void_p,
                              ctypes.c_void_p, ctypes.POINTER(ctypes.c_void_p))


def flatten(path):
    """CGPath -> list of contours, each a list of (x, y), as src/text.inc does."""
    contours, cur = [], [None, None]

    def applier(info, elem):
        t = ctypes.cast(elem, ctypes.POINTER(ctypes.c_int)).contents.value
        pts = ctypes.cast(ctypes.cast(elem, ctypes.POINTER(ctypes.c_void_p))[1],
                          ctypes.POINTER(ctypes.c_double))
        if t == 0:                                   # move: start a contour
            contours.append([])
            contours[-1].append((pts[0], pts[1]))
            cur[0], cur[1] = pts[0], pts[1]
        elif t == 1:                                 # line
            contours[-1].append((pts[0], pts[1]))
            cur[0], cur[1] = pts[0], pts[1]
        elif t == 2:                                 # quadratic
            cx, cy, ex, ey = pts[0], pts[1], pts[2], pts[3]
            for i in range(1, STEPS + 1):
                s = i / STEPS
                u = 1 - s
                contours[-1].append((u * u * cur[0] + 2 * u * s * cx + s * s * ex,
                                     u * u * cur[1] + 2 * u * s * cy + s * s * ey))
            cur[0], cur[1] = ex, ey
        elif t == 3:                                 # cubic
            ax, ay, bx, by, ex, ey = (pts[i] for i in range(6))
            for i in range(1, STEPS + 1):
                s = i / STEPS
                u = 1 - s
                a, b = u * u * u, 3 * u * u * s
                c, d = 3 * u * s * s, s * s * s
                contours[-1].append((a * cur[0] + b * ax + c * bx + d * ex,
                                     a * cur[1] + b * ay + c * by + d * ey))
            cur[0], cur[1] = ex, ey
        # t == 4 (close) needs nothing: the next move ends the contour

    cg.CGPathApply(path, None, APPLIER(applier))
    return contours


def tessellate(contours):
    """The contours through GLU, out as a flat triangle list of (x, y)."""
    verts = []          # index -> (x, y); kept alive for the callbacks
    keep = []
    tris, run, mode = [], [], [0]

    def on_begin(m):
        mode[0] = m
        run.clear()

    def on_vertex(data):
        run.append(verts[ctypes.cast(data, ctypes.c_void_p).value - 1])

    def on_end():
        m = mode[0]
        if m == GL_TRIANGLES:
            tris.extend(run)
        elif m == GL_TRIANGLE_FAN:
            for i in range(1, len(run) - 1):
                tris.extend([run[0], run[i], run[i + 1]])
        elif m == GL_TRIANGLE_STRIP:
            for i in range(len(run) - 2):
                tris.extend([run[i], run[i + 1], run[i + 2]] if i % 2 == 0
                            else [run[i + 1], run[i], run[i + 2]])
        else:
            raise SystemExit('unexpected tessellator primitive %d' % m)

    def on_combine(coords, data, weight, out):
        verts.append((coords[0], coords[1]))
        out[0] = ctypes.c_void_p(len(verts))

    cb = [CB_BEGIN(on_begin), CB_VERTEX(on_vertex), CB_END(on_end), CB_COMBINE(on_combine)]
    t = glu.gluNewTess()
    for which, f in zip([GLU_TESS_BEGIN, GLU_TESS_VERTEX, GLU_TESS_END, GLU_TESS_COMBINE], cb):
        glu.gluTessCallback(t, which, ctypes.cast(f, ctypes.c_void_p))
    glu.gluTessProperty(t, GLU_TESS_WINDING_RULE, float(GLU_TESS_WINDING_NONZERO))
    glu.gluTessNormal(t, 0.0, 0.0, 1.0)

    glu.gluTessBeginPolygon(t, None)
    for c in contours:
        glu.gluTessBeginContour(t)
        for (x, y) in c:
            verts.append((x, y))
            arr = (ctypes.c_double * 3)(x, y, 0.0)
            keep.append(arr)
            glu.gluTessVertex(t, arr, ctypes.c_void_p(len(verts)))
        glu.gluTessEndContour(t)
    glu.gluTessEndPolygon(t)
    return tris


def main():
    if sys.platform != 'darwin':
        raise SystemExit('needs macOS: this drives CoreText and the GLU tessellator')

    name = cf.CFStringCreateWithCString(None, FONT, 0x08000100)
    font = ct.CTFontCreateWithName(name, 1.0, None)

    out = {}
    for ch in sorted(set(TEXT)):
        u = ctypes.c_uint16(ord(ch))
        g = ctypes.c_uint16(0)
        if not ct.CTFontGetGlyphsForCharacters(font, ctypes.byref(u), ctypes.byref(g), 1):
            raise SystemExit('no glyph for %r in %s' % (ch, FONT.decode()))
        adv = ct.CTFontGetAdvancesForGlyphs(font, 0, ctypes.byref(g), None, 1)
        path = ct.CTFontCreatePathForGlyph(font, g, None)
        tris = tessellate(flatten(path)) if path else []
        out[ord(ch)] = (adv, tris)

    q = lambda v: repr(round(v, 5))
    src = ["// Generated by tools/extract_glyphs.py - do not edit.",
           "//",
           "// The credits' glyphs, as the Win32 original's wglUseFontOutlinesA display",
           "// lists: Arial Bold outlines at em size 1.0, filled, followed by the glyph's",
           "// advance.  CoreText supplied the outlines and the GLU tessellator the",
           "// triangles, which is exactly what ../macos-x86_64/src/text.inc does at",
           "// start-up - so this is the same geometry, not an approximation.",
           "//",
           "// Keyed by character code, because glCallLists indexes lists by the bytes of",
           "// the string.  `a` is the advance, `t` a flat triangle list of x, y pairs.",
           '',
           'export const glyphs = {']
    total = 0
    for code, (adv, tris) in sorted(out.items()):
        total += len(tris)
        flat = ', '.join(q(c) for xy in tris for c in xy)
        src.append('  %d: { a: %s, t: [%s] },   // %s' % (code, q(adv), flat, chr(code)))
    src.append('};')
    open(OUT, 'w').write('\n'.join(src) + '\n')
    print('wrote %s' % OUT)
    print('  %d glyphs, %d triangles, %d bytes' %
          (len(out), total // 3, os.path.getsize(OUT)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
