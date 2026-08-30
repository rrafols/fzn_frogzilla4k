; ---------------------------------------------------------------------------
;  The arrangement: which camera is live during each 100-tick slice of the
;  intro's timeline.
;
;  The visuals run on "ts", a clock in which twelve module rows (one order)
;  advance it by 99.  dacamera = (ts - 800) / 100 indexes this table, so entry
;  N covers ts in [800 + 100N, 900 + 100N) - a little over one order each.
;  Below entry 0 (ts < 800) and from entry 36 on, no camera transform is
;  applied at all; at 45 the intro ends.
;
;  Each port defines CAM before including this: the Win32 original expands it
;  to a jump-table entry, the macOS port to a plain index byte.
;
;      0  low tracking shot, sliding in over the city
;      1  orbit, 50 degrees down
;      2  slow orbit, 40 degrees down, higher
;      3  orbit, 30 degrees down, close
;      4  street level, riding along with the traffic
;      5  chase camera locked to Freddy the frog
; ---------------------------------------------------------------------------

    CAM 0       ; 00   ts  800.. 900
    CAM 0       ; 01
    CAM 1       ; 02
    CAM 1       ; 03
    CAM 2       ; 04
    CAM 2       ; 05
    CAM 3       ; 06
    CAM 3       ; 07
    CAM 0       ; 08
    CAM 0       ; 09
    CAM 1       ; 10
    CAM 1       ; 11
    CAM 2       ; 12
    CAM 2       ; 13
    CAM 3       ; 14
    CAM 3       ; 15
    CAM 4       ; 16
    CAM 4       ; 17
    CAM 4       ; 18
    CAM 4       ; 19
    CAM 4       ; 20
    CAM 1       ; 21
    CAM 2       ; 22
    CAM 3       ; 23
    CAM 4       ; 24
    CAM 4       ; 25
    CAM 4       ; 26
    CAM 4       ; 27
    CAM 4       ; 28
    CAM 1       ; 29
    CAM 1       ; 30
    CAM 1       ; 31
    CAM 5       ; 32   Freddy arrives - the destruction starts at ts 3100
    CAM 5       ; 33
    CAM 5       ; 34
    CAM 5       ; 35
    CAM 1       ; 36   dummy; never selected, dacamera >= 36 draws no camera
