#!/usr/bin/env python3
"""
A stand-in for fuxnasm.exe, the DOS filter the original build ran over every
source file: it rewrites  #1.0#  into the hex of that float's 32-bit bit
pattern, so the intro can push a float as an immediate.

    fuxnasm <in.asm >out.asm          (the original, DOS only)
    python3 fuxnasm.py <in.asm >out.asm

Byte-for-byte identical output to fuxnasm.exe on this project's sources, which
is what lets the Win32 tree be assembled and checked from a Unix machine.
"""
import re, struct, sys

FLOAT = re.compile(r'#\s*([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)#')


def sub(m):
    bits, = struct.unpack('<I', struct.pack('<f', float(m.group(1))))
    return '0x%08x' % bits


def main():
    data = sys.stdin.buffer.read().decode('latin-1')
    sys.stdout.buffer.write(FLOAT.sub(sub, data).encode('latin-1'))


if __name__ == '__main__':
    main()
