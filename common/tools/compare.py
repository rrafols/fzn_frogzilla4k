#!/usr/bin/env python3
"""Compare two directories of rendered frames (and the mixed tune)."""
import sys, os, glob

# Frogzilla reseeds its PRNG at fixed points inside every frame, so nothing
# here depends on the wall clock: the two builds have to agree exactly.
RANDOM_FRAMES = set()

def main(a, b):
    diff = [os.path.basename(f) for f in sorted(glob.glob(os.path.join(a, 'shot*.ppm')))
            if open(f, 'rb').read() != open(os.path.join(b, os.path.basename(f)), 'rb').read()]
    n = len(glob.glob(os.path.join(a, 'shot*.ppm')))
    unexpected = [f for f in diff if f not in RANDOM_FRAMES]
    print('frames: %d compared, %d identical' % (n, n - len(diff)))
    print('differing: %s' % (', '.join(diff) or 'none'))
    wav = [os.path.join(d, 'song.wav') for d in (a, b)]
    if all(os.path.exists(w) for w in wav):
        print('audio: %s' % ('identical' if open(wav[0],'rb').read() == open(wav[1],'rb').read()
                             else 'DIFFERENT'))
    if unexpected:
        print('\nUNEXPECTED differences: %s' % ', '.join(unexpected))
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
