; suxored module by itsuxor version 004 codename "* bpZzzz slaps ccm_ around a bit with a large trout"

; file name: 'wnd_fzil.it'
; module title: 'Frogzilla'
; created with tracker 2.18
; format version 1.1
; 53 orders, 0 instruments, 8 samples, 14 patterns
; global volume (0->128): 128
; mix volume (0->128): 48
; initial speed: 8
; initial tempo: 120
; base octave: 3


%define maxOrderList	54
orderList:
	db 000, 000, 000, 000, 001, 000, 000, 000
	db 002, 003, 004, 005, 002, 003, 004, 005
	db 002, 003, 004, 005, 002, 003, 004, 005
	db 006, 006, 006, 006, 007, 008, 009, 010
	db 011, 011, 011, 011, 012, 012, 012, 012
	db 011, 011, 011, 011, 011, 011, 011, 013
	db 010, 010, 010, 010, 014, 014

%define maxPatterns	15
patternList:	
	;db 000, 255, 255, 255, 255, 255, 255, 255
	db 000, 001, 255, 255, 255, 255, 255, 255 ; pattern 000
	db 000, 001, 002, 255, 255, 255, 255, 255 ; pattern 001
	db 003, 001, 004, 005, 006, 007, 008, 009 ; pattern 002
	db 003, 001, 255, 010, 006, 011, 008, 012 ; pattern 003
	db 003, 001, 002, 005, 013, 014, 008, 015 ; pattern 004
	db 003, 001, 255, 010, 013, 255, 008, 015 ; pattern 005
	db 000, 001, 255, 255, 255, 255, 016, 255 ; pattern 006
	db 255, 023, 255, 017, 255, 255, 037, 018 ; pattern 007
	db 255, 023, 255, 019, 255, 255, 037, 020 ; pattern 008
	db 024, 023, 255, 021, 255, 255, 037, 022 ; pattern 009
	db 024, 255, 255, 021, 255, 255, 255, 022 ; pattern 010
	db 025, 026, 027, 021, 028, 029, 030, 031 ; pattern 011
	db 003, 001, 032, 021, 033, 034, 035, 036 ; pattern 012
	db 025, 038, 027, 021, 028, 029, 030, 031 ; pattern 013
	db 255, 255, 255, 255, 255, 255, 255, 255

%define NT(_n,_o,_v) (_n | (_o << 4) | (_v << 6))
%define maxChannels	40
channelList:

	; channel 000
	db 000        ; sample	;0
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(10,1,2) ; A-4 01 40 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. C00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 001
	db 001        ; sample
	db NT(12,3,3) ; B-6 02 .. .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,2) ; B-6 02 40 .00 

	db NT(01,3,2) ; C-6 02 40 .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(01,3,3) ; C-6 02 .. .00 
	db NT(12,3,1) ; B-6 02 20 .00 

	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,1) ; B-6 02 20 .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 002
	db 002        ; sample
	db NT(05,1,3) ; E-4 03 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 003
	db 000        ; sample
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(10,1,2) ; A-4 01 40 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. C00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 004
	db 002        ; sample
	db NT(10,1,3) ; A-4 03 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 005
	db 003        ; sample
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(08,1,1) ; G-4 04 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(08,1,3) ; G-4 04 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(01,2,1) ; C-5 04 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(01,2,2) ; C-5 04 40 .00 
	db NT(01,2,1) ; C-5 04 20 .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 006
	db 004        ; sample
	db NT(05,2,3) ; E-5 05 .. .00 
	db NT(05,1,1) ; E-4 05 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(05,1,2) ; E-4 05 40 .00 
	
	db NT(05,1,3) ; E-4 05 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(05,2,2) ; E-5 05 40 .00 
	db NT(05,1,3) ; E-4 05 .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(05,2,1) ; E-5 05 20 .00 
	db NT(05,1,3) ; E-4 05 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 007
	db 005        ; sample
	db NT(01,2,3) ; C-5 06 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 008
	db 006        ; sample
	db NT(05,2,3) ; E-5 07 .. .00 
	db NT(12,0,2) ; B-3 07 40 GFF 
	db NT(03,2,3) ; D-5 07 .. GFF 
	db NT(05,1,2) ; E-4 07 40 GFF 
	
	db NT(08,2,3) ; G-5 07 .. .00 
	db NT(12,1,2) ; B-4 07 40 GFF 
	db NT(05,2,3) ; E-5 07 .. .00 
	db NT(12,1,2) ; B-4 07 40 GFF 
	
	db NT(08,2,3) ; G-5 07 .. GFF 
	db NT(05,1,2) ; E-4 07 40 GFF 
	db NT(03,2,3) ; D-5 07 .. .00 
	db NT(12,0,2) ; B-3 07 40 GFF 
	
	db 0
	db 1
	db 1
	db 1
	
	db 0
	db 1
	db 0
	db 1
	
	db 1
	db 1
	db 0
	db 1

	; channel 009
	db 007        ; sample
	db NT(10,2,3) ; A-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,2,1) ; A-5 08 20 .00 
	db NT(10,2,2) ; A-5 08 40 .00 

	db NT(10,2,3) ; A-5 08 .. .00 
	db NT(10,1,1) ; A-4 08 20 .00 
	db NT(10,2,3) ; A-5 08 .. .00 
	db NT(10,1,3) ; A-4 08 .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,1) ; A-4 08 20 .00 
	db NT(10,2,3) ; A-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 010
	db 003        ; sample
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(08,1,1) ; G-4 04 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(08,1,3) ; G-4 04 .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(01,2,2) ; C-5 04 40 .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 011
	db 005        ; sample
	db NT(12,1,3) ; B-4 06 .. GFF 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0;		1
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 012
	db 007        ; sample
	db NT(08,2,3) ; G-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(08,2,1) ; G-5 08 20 .00 
	db NT(08,2,2) ; G-5 08 40 .00 

	db NT(08,2,3) ; G-5 08 .. .00 
	db NT(08,1,1) ; G-4 08 20 .00 
	db NT(08,2,3) ; G-5 08 .. .00 
	db NT(08,1,3) ; G-4 08 .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(08,1,1) ; G-4 08 20 .00 
	db NT(08,2,3) ; G-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 013
	db 004        ; sample
	db NT(12,1,3) ; B-4 05 .. .00 
	db NT(12,0,1) ; B-3 05 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(12,0,2) ; B-3 05 40 .00 

	db NT(12,0,3) ; B-3 05 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(12,1,2) ; B-4 05 40 .00 
	db NT(12,0,3) ; B-3 05 .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(12,1,1) ; B-4 05 20 .00 
	db NT(12,0,3) ; B-3 05 .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0


	; channel 014
	db 005        ; sample
	db NT(05,1,3) ; E-4 06 .. GFF 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0		;1
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 015
	db 007        ; sample
	db NT(05,2,3) ; E-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(05,2,1) ; E-5 08 20 .00 
	db NT(05,2,2) ; E-5 08 40 .00 
	
	db NT(05,2,3) ; E-5 08 .. .00 
	db NT(05,1,1) ; E-4 08 20 .00 
	db NT(05,2,3) ; E-5 08 .. .00 
	db NT(05,1,3) ; E-4 08 .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(05,1,1) ; E-4 08 20 .00 
	db NT(05,2,3) ; E-5 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0


	; channel 016
	db 006        ; sample
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,3,3) ; E-6 07 .. GFF 
	db NT(05,1,2) ; E-4 07 40 GFF 

	db NT(05,2,3) ; E-5 07 .. .00 
	db NT(05,3,2) ; E-6 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 

	db NT(06,3,3) ; F-6 07 .. GFF 
	db NT(06,1,2) ; F-4 07 40 GFF 
	db NT(06,2,3) ; F-5 07 .. .00 
	db NT(06,3,2) ; F-6 07 40 GFF 

	db 0
	db 1
	db 1
	db 1

	db 0
	db 1
	db 0
	db 1

	db 1
	db 1
	db 0
	db 1

	; channel 017
	db 003        ; sample
	db NT(01,0,1) ; C-3 04 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0


	; channel 018
	db 007        ; sample
	db NT(05,0,1) ; E-3 08 20 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 019
	db 003        ; sample
	db NT(01,0,2) ; C-3 04 40 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0


	; channel 020
	db 007        ; sample
	db NT(05,0,2) ; E-3 08 40 .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0


	; channel 021
	db 003        ; sample
	db NT(01,0,3) ; C-3 04 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0


	; channel 022
	db 007        ; sample
	db NT(05,0,3) ; E-3 08 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 023
	db 001        ; sample
	db NT(12,3,3) ; B-6 02 .. .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,3,1) ; B-6 02 20 .00 

	db NT(12,3,3) ; B-6 02 .. .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,3,1) ; B-6 02 20 .00 

	db NT(12,3,3) ; B-6 02 .. .00 
	db NT(12,3,1) ; B-6 02 20 .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,3,1) ; B-6 02 20 .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 024
	db 000        ; sample
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 

	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(00,0,0) ; ... .. .. C00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0


	; channel 025
	db 000        ; sample
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. .00 
	db NT(10,1,3) ; A-4 01 .. .00 
	db NT(00,0,0) ; ... .. .. C00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 026
	db 001        ; sample
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 027
	db 002        ; sample
	db NT(05,1,3) ; E-4 03 .. .00 
	db NT(05,2,3) ; E-5 03 .. GFF 
	db NT(05,1,3) ; E-4 03 .. GFF 
	db NT(03,1,3) ; D-4 03 .. GFF 
	
	db NT(05,1,3) ; E-4 03 .. GFF 
	db NT(05,2,3) ; E-5 03 .. GFF 
	db NT(05,1,3) ; E-4 03 .. GFF 
	db NT(03,1,3) ; D-4 03 .. GFF 
	
	db NT(06,1,3) ; F-4 03 .. GFF 
	db NT(05,2,3) ; E-5 03 .. GFF 
	db NT(03,1,3) ; D-4 03 .. GFF 
	db NT(06,1,3) ; F-4 03 .. GFF 
	
	db 0
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1

	; channel 028
	db 004        ; sample
	db NT(12,2,3) ; B-5 05 .. .00 
	db NT(12,1,3) ; B-4 05 .. .00 
	db NT(12,0,3) ; B-3 05 .. .00 
	db NT(12,2,3) ; B-5 05 .. .00 
	
	db NT(12,1,3) ; B-4 05 .. .00 
	db NT(12,0,3) ; B-3 05 .. .00 
	db NT(12,2,3) ; B-5 05 .. .00 
	db NT(12,1,3) ; B-4 05 .. .00 
	
	db NT(01,3,3) ; C-6 05 .. .00 
	db NT(12,1,3) ; B-4 05 .. .00 
	db NT(10,1,3) ; A-4 05 .. .00 
	db NT(01,2,3) ; C-5 05 .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 029
	db 005        ; sample
	db NT(05,2,3) ; E-5 06 .. .00 
	db NT(05,1,3) ; E-4 06 .. GFF 
	db NT(08,1,3) ; G-4 06 .. GFF 
	db NT(12,1,3) ; B-4 06 .. GFF 

	db NT(05,1,3) ; E-4 06 .. GFF 
	db NT(05,2,3) ; E-5 06 .. GFF 
	db NT(05,1,3) ; E-4 06 .. GFF 
	db NT(08,1,3) ; G-4 06 .. GFF 
	
	db NT(10,1,3) ; A-4 06 .. GFF 
	db NT(05,1,3) ; E-4 06 .. GFF 
	db NT(03,2,3) ; D-5 06 .. GFF 
	db NT(05,1,3) ; E-4 06 .. GFF 
	
	db 0
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1


	; channel 030
	db 006        ; sample
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. GFF 
	db NT(05,2,2) ; E-5 07 40 GFF 

	db NT(05,3,3) ; E-6 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 

	db NT(06,3,3) ; F-6 07 .. GFF 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(03,3,3) ; D-6 07 .. .00 
	db NT(06,2,2) ; F-5 07 40 GFF 

	db 0
	db 1
	db 1
	db 1

	db 0
	db 1
	db 0
	db 1

	db 1
	db 1
	db 0
	db 1

	; channel 031
	db 007        ; sample
	db NT(05,0,3) ; E-3 08 .. .00 
	db NT(05,1,2) ; E-4 08 40 .00 
	db NT(05,0,3) ; E-3 08 .. .00 
	db NT(08,1,2) ; G-4 08 40 .00 

	db NT(05,0,3) ; E-3 08 .. .00 
	db NT(12,1,2) ; B-4 08 40 .00 
	db NT(05,2,3) ; E-5 08 .. .00 
	db NT(05,0,2) ; E-3 08 40 .00 

	db NT(06,0,3) ; F-3 08 .. .00 
	db NT(05,1,2) ; E-4 08 40 .00 
	db NT(03,1,3) ; D-4 08 .. .00 
	db NT(06,1,2) ; F-4 08 40 .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 032
	db 002        ; sample
	db NT(08,1,3) ; G-4 03 .. .00 
	db NT(08,2,3) ; G-5 03 .. GFF 
	db NT(08,1,3) ; G-4 03 .. GFF 
	db NT(06,1,3) ; F-4 03 .. GFF 

	db NT(08,1,3) ; G-4 03 .. GFF 
	db NT(08,2,3) ; G-5 03 .. GFF 
	db NT(08,1,3) ; G-4 03 .. GFF 
	db NT(06,1,3) ; F-4 03 .. GFF 

	db NT(09,1,3) ; G#4 03 .. GFF 
	db NT(08,2,3) ; G-5 03 .. GFF 
	db NT(06,1,3) ; F-4 03 .. GFF 
	db NT(09,1,3) ; G#4 03 .. GFF 

	db 0
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1

	; channel 033
	db 004        ; sample
	db NT(03,3,3) ; D-6 05 .. .00 
	db NT(03,2,3) ; D-5 05 .. .00 
	db NT(03,1,3) ; D-4 05 .. .00 
	db NT(03,3,3) ; D-6 05 .. .00 
	
	db NT(03,2,3) ; D-5 05 .. .00 
	db NT(03,1,3) ; D-4 05 .. .00 
	db NT(03,3,3) ; D-6 05 .. .00 
	db NT(03,2,3) ; D-5 05 .. .00 
	
	db NT(04,3,3) ; D#6 05 .. .00 
	db NT(03,2,3) ; D-5 05 .. .00 
	db NT(01,2,3) ; C-5 05 .. .00 
	db NT(04,2,3) ; D#5 05 .. .00 
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0
	
	db 0
	db 0
	db 0
	db 0

	; channel 034
	db 005        ; sample
	db NT(08,2,3) ; G-5 06 .. .00 
	db NT(08,1,3) ; G-4 06 .. GFF 
	db NT(11,1,3) ; A#4 06 .. GFF 
	db NT(03,2,3) ; D-5 06 .. GFF 
	
	db NT(08,1,3) ; G-4 06 .. GFF 
	db NT(08,2,3) ; G-5 06 .. GFF 
	db NT(08,1,3) ; G-4 06 .. GFF 
	db NT(11,1,3) ; A#4 06 .. GFF 
	
	db NT(01,2,3) ; C-5 06 .. GFF 
	db NT(08,1,3) ; G-4 06 .. GFF 
	db NT(06,2,3) ; F-5 06 .. GFF 
	db NT(08,1,3) ; G-4 06 .. GFF 
	
	db 0
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1
	
	db 1
	db 1
	db 1
	db 1


	; channel 035
	db 006        ; sample
	db NT(08,1,3) ; G-4 07 .. .00 
	db NT(08,2,2) ; G-5 07 40 GFF 
	db NT(08,1,3) ; G-4 07 .. GFF 
	db NT(08,2,2) ; G-5 07 40 GFF 

	db NT(08,3,3) ; G-6 07 .. .00 
	db NT(08,2,2) ; G-5 07 40 GFF 
	db NT(08,1,3) ; G-4 07 .. .00 
	db NT(08,2,2) ; G-5 07 40 GFF 

	db NT(09,3,3) ; G#6 07 .. GFF 
	db NT(08,2,2) ; G-5 07 40 GFF 
	db NT(06,3,3) ; F-6 07 .. .00 
	db NT(09,2,2) ; G#5 07 40 GFF 

	db 0
	db 1
	db 1
	db 1

	db 0
	db 1
	db 0
	db 1

	db 1
	db 1
	db 0
	db 1


	; channel 036
	db 007        ; sample
	db NT(08,0,3) ; G-3 08 .. .00 
	db NT(08,1,2) ; G-4 08 40 .00 
	db NT(08,0,3) ; G-3 08 .. .00 
	db NT(11,1,2) ; A#4 08 40 .00 

	db NT(08,0,3) ; G-3 08 .. .00 
	db NT(03,2,2) ; D-5 08 40 .00 
	db NT(08,2,3) ; G-5 08 .. .00 
	db NT(08,0,2) ; G-3 08 40 .00 

	db NT(09,0,3) ; G#3 08 .. .00 
	db NT(08,1,2) ; G-4 08 40 .00 
	db NT(06,1,3) ; F-4 08 .. .00 
	db NT(09,1,2) ; G#4 08 40 .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	; channel 037
	db 006        ; sample
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. GFF 
	db NT(05,2,2) ; E-5 07 40 GFF 
	
	db NT(05,3,3) ; E-6 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	
	db NT(05,3,3) ; E-6 07 .. GFF 
	db NT(05,2,2) ; E-5 07 40 GFF 
	db NT(05,1,3) ; E-4 07 .. .00 
	db NT(05,2,2) ; E-5 07 40 GFF 
	
	db 0
	db 1
	db 1
	db 1
	
	db 0
	db 1
	db 0
	db 1
	
	db 1
	db 1
	db 0
	db 1


	; channel 038
	db 001        ; sample
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 

	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,3,2) ; B-6 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 

	db NT(12,2,2) ; B-5 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 
	db NT(12,2,2) ; B-5 02 40 .00 
	db NT(12,2,3) ; B-5 02 .. .00 

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0

	db 0
	db 0
	db 0
	db 0
	
; 1485 bytes

