#!/usr/bin/env python3
"""Flatten the intro into one self-contained HTML file.

index.html and src/ already depend on nothing outside this directory and fetch
nothing at run time, so the port is portable as it stands - but ES modules are
fetched, and a browser refuses to fetch them over file://.  This writes a
single build/frogzilla.html with every module inlined as a classic script, which
opens by double-clicking, with no server and no other file beside it.

The transform is deliberately small: it handles only the four import/export
forms the port actually uses, and fails loudly on anything else rather than
quietly producing a file that half works.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
# One implementation of "what does this module declare", shared with pack.py:
# the two bundlers must agree about it or they build different intros.
from pack import declared_names, strip_comments_and_strings  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, '..'))
SRC = os.path.join(ROOT, 'src')
OUT = os.path.join(ROOT, 'build', 'frogzilla.html')

# Everything index.html reaches, in dependency order.  src/x87.js and
# src/sgen_x87.js are not here on purpose: they are the x87 emulator the audio
# is checked against by tools/check_audio.mjs, and the intro never imports them.
MODULES = ['data.js', 'glyphs.js', 'sgen.js', 'player.js', 'glfixed.js',
           'draw.js', 'frame.js', 'intro.js']

# A module registry small enough to read: each module is a function that fills
# its own exports the first time something asks for it.
RUNTIME = """\
// Bundled by tools/bundle.py - the modules below are src/*.js, unchanged apart
// from their import and export statements.  Edit those, not this file.
const __mods = {}, __done = {};
const __def = (name, fn) => { __mods[name] = fn; };
const __req = (name) => {
  if (!__done[name]) { __done[name] = {}; __mods[name](__done[name], __req); }
  return __done[name];
};
"""

RE_NAMED = re.compile(r"import\s*\{(.*?)\}\s*from\s*'(?:\./)?(?:src/)?([\w.]+)';", re.S)
RE_STAR = re.compile(r"import\s*\*\s*as\s+(\w+)\s+from\s*'(?:\./)?(?:src/)?([\w.]+)';")
RE_EXPORT_FN = re.compile(r'^export\s+(?:(?:async\s+)?function|class)\s+([A-Za-z_$][\w$]*)', re.M)
RE_EXPORT_BINDING = re.compile(r'^export\s+(?:const|let|var)\s', re.M)
RE_ANY_IMPORT = re.compile(r'^\s*import\b', re.M)
RE_ANY_EXPORT = re.compile(r'^\s*export\b', re.M)


def rewrite(src, what):
    """Turn one module's source into a body plus the names it exports."""
    # Over a copy with comments and strings blanked, so that neither a `;` in
    # a string nor an `export` in a comment can move the answer.
    code = strip_comments_and_strings(src)
    names = RE_EXPORT_FN.findall(code)
    for m in RE_EXPORT_BINDING.finditer(code):
        names += declared_names(code, m.start())

    # `export let`/`export var` would need live bindings, which this registry
    # does not give; nothing in the port uses them, so refuse rather than guess.
    for bad in re.finditer(r'^export\s+(let|var|default|\*)', src, re.M):
        sys.exit('%s: unsupported `export %s`' % (what, bad.group(1)))

    src = RE_NAMED.sub(lambda m: "const {%s} = __req('%s');" % (m.group(1).strip(), m.group(2)), src)
    src = RE_STAR.sub(lambda m: "const %s = __req('%s');" % (m.group(1), m.group(2)), src)
    src = re.sub(r'^export\s+', '', src, flags=re.M)

    leftover = (RE_ANY_IMPORT.search(strip_comments_and_strings(src)) or
                RE_ANY_EXPORT.search(strip_comments_and_strings(src)))
    if leftover:
        line = src[:leftover.start()].count('\n') + 1
        sys.exit('%s:%d: import/export form the bundler does not handle' % (what, line))
    return src, names


def check_imports(exported):
    """Every name imported anywhere must be one the source module exports.

    A missing export is not a syntax error at run time - it arrives as
    `undefined` wherever it is used, which for a name like ONEV means the glow
    is drawn in no colour at all and the intro merely looks wrong.  So the
    names are reconciled here instead, before the file is written.
    """
    bad = []
    for name in MODULES + ['../index.html']:
        path = os.path.join(SRC, name) if name in MODULES else os.path.join(ROOT, 'index.html')
        src = open(path).read()
        for spec, mod in RE_NAMED.findall(src):
            if mod not in exported:
                continue
            for want in (w.strip().split()[0] for w in spec.split(',') if w.strip()):
                if want not in exported[mod]:
                    bad.append('%s imports `%s` from %s, which does not export it'
                               % (name, want, mod))
    if bad:
        sys.exit('\n'.join(bad))


def main():
    parts = [RUNTIME]
    exported = {}
    for name in MODULES:
        body, names = rewrite(open(os.path.join(SRC, name)).read(), 'src/' + name)
        exported[name] = set(names)
        parts.append("__def('%s', function (exports, __req) {\n%s\nObject.assign(exports, "
                     "{ %s });\n});\n" % (name, body, ', '.join(names)))
    check_imports(exported)

    page = open(os.path.join(ROOT, 'index.html')).read()
    m = re.search(r'<script type="module">(.*?)</script>', page, re.S)
    if not m:
        sys.exit('index.html: could not find the module script')
    body, _ = rewrite(m.group(1), 'index.html')

    # The page script uses top-level await, which a classic script cannot.
    parts.append('(async () => {\n%s\n})();\n' % body)

    html = page[:m.start()] + '<script>\n' + '\n'.join(parts) + '</script>' + page[m.end():]
    html = re.sub(r'(<title>.*?</title>)',
                  r'\1\n<!-- self-contained build: open this file directly, '
                  'no server needed -->', html, count=1, flags=re.S)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w').write(html)
    print('wrote %s (%.1f KB)' % (OUT, len(html.encode()) / 1024))
    return 0


if __name__ == '__main__':
    sys.exit(main())
