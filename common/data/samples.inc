%if 0
struc perxxor
	.wavetype	resb	1
	.nsamples	resw	1	;u
	.freqini	resw	1
	.dfreq		resw	1
	.ddfreq		resw	1	;!!
	.ampini		resb	1
	.damp		resb	1
	.cutini		resb	1	;u
	.dcut		resb	1
	.resini		resb	1
	.dres		resb	1
	.randgain	resb	1	;u
%endif

samples:
; 0
smp_20	db	2	;wavetype
	dw	187	;nsamples
	dw	779	;freqini
	dw	-2000	;dfreq
	dw	0	;ddfreq
	db	107	;ampini
	db	-105	;damp
	db	77	;cutini
	db	-74	;dcut
	db	48	;resini
	db	-65	;dres
	db	0	;randgain

; 1
smp_8	db	1	;wavetype
	dw	1000	;nsamples
	dw	0	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	68	;ampini
	db	-67	;damp
	db	253	;cutini
	db	-49	;dcut
	db	25	;resini
	db	-17	;dres
	db	255	;randgain
	
; 2
smp_6	db	0	;wavetype
	dw	8250	;nsamples
	dw	81	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	77	;ampini
	db	-74	;damp
	db	68	;cutini
	db	-69	;dcut
	db	84	;resini
	db	12	;dres
	db	0	;randgain

; 3
smp_8_	db	1	;wavetype
	dw	1000	;nsamples
	dw	0	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	68	;ampini
	db	-67	;damp
	db	253	;cutini
	db	-49	;dcut
	db	25	;resini
	db	-17	;dres
	db	255	;randgain

; 4
smp_10	db	0	;wavetype
	dw	1000	;nsamples
	dw	220	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	100	;ampini
	db	-99	;damp
	db	50	;cutini
	db	-38	;dcut
	db	-31	;resini
	db	118	;dres
	db	0	;randgain

; 5
smp_9	db	2	;wavetype
	dw	21250	;nsamples
	dw	440	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	109	;ampini
	db	-108	;damp
	db	12	;cutini
	db	30	;dcut
	db	82	;resini
	db	-90	;dres
	db	255	;randgain

; 6
smp_11	db	1	;wavetype
	dw	3000	;nsamples
	dw	440	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	100	;ampini
	db	-99	;damp
	db	93	;cutini
	db	-90	;dcut
	db	-89	;resini
	db	41	;dres
	db	0	;randgain

; 7	
smp_1	db	2	;wavetype
	dw	500	;nsamples
	dw	110	;freqini
	dw	0	;dfreq
	dw	0	;ddfreq
	db	53	;ampini
	db	0	;damp
	db	102	;cutini
	db	-81	;dcut
	db	-40	;resini
	db	-123	;dres
	db	13	;randgain