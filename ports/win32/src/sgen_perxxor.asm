struc perxxor
	.wavetype	resb	1
	.nsamples	resw	1
	.freqini	resw	1
	.dfreq		resw	1
	.ddfreq		resw	1
	.ampini		resb	1
	.damp		resb	1
	.cutini		resb	1
	.dcut		resb	1
	.resini		resb	1
	.dres		resb	1
	.randgain	resb	1
endstruc

myRandFloat:	
	mov	eax, [ABS(holdrand)]
	imul	eax, 214013
	add	eax, 2531011
	mov	[ABS(holdrand)], eax
	push	ax
	fild	word [esp]
	pop	ax
	fidiv	word [ABS(icnt32k)]
	
	ret

;esi -> pointer to structure...
;edi -> output buffer
RenderSample:
	finit				;just to be safe...
	;xor	eax, eax
	mov 	ebp, ABS(perxxorVars)
	;mov 	[ebp], eax
	;mov	[ebp+4], eax
	;mov	[ebp+8], eax
	
	movzx	eax,word [esi+perxxor.nsamples]
	shl	eax,4

	;mov	[ABS(nsamples)],eax
	push	eax
		
;	float		fVal = p->freqIni;
	fild	word [esi+perxxor.freqini]
	fstp	dword [ebp+12]		;fVal
	
;	float		fdVal = 1.f + p->dFreq / (16.f*256.f*256.f); //65536.f;
	fild	word [esi+perxxor.dfreq]
	fmul	dword [ABS(fcnt_inv16M)]
	fld1
	faddp	st1,st0
	fstp	dword [ebp+16]		;fdVal

;	volatile float		amp = p->ampIni/100.f;
	

	movsx	eax,byte [esi+perxxor.dcut]
	push	eax
	fild	dword [esp]
	pop	eax

	movsx	eax,byte [esi+perxxor.dres]
	push	eax
	fild	dword [esp]
	pop	eax

	movsx	eax,byte [esi+perxxor.resini]
	push	eax
	fild	dword [esp]
	pop	eax

	movzx	eax,byte [esi+perxxor.cutini]		;unsigned!!
	push	eax
	fild	dword [esp]
	pop	eax

	movsx	eax,byte [esi+perxxor.ampini]
	push	eax
	fild	dword [esp]
	pop	eax

	movsx	eax,byte [esi+perxxor.damp]
	push	eax
	fild	dword [esp]
	pop	eax

	; damp
	fidiv	word [ABS(icnt100)]
	fstp	dword [ABS(amp)]
	
	; ampini
	fidiv	word [ABS(icnt100)]
	;fidiv	dword [ABS(nsamples)]
	fidiv	dword [esp]		;nsamples
	fstp	dword [ebp+32]		;damp
	
	; cutini
	fmul	dword [ABS(fcnt0d0019)]
	fstp	dword [ebp+04]		;f
	
	; resini
	fidiv	word [ABS(icnt100)]
	fstp	dword [ebp+08]		;q
	
	; dres
	fidiv	word [ABS(icnt100)]
	fidiv	dword [esp]		;nsamples
	fstp	dword [ebp+24]		;dres
	
	; dcut
	fmul	dword [ABS(fcnt0d0019)]
	fidiv	dword [esp]		;nsamples
	fstp	dword [ebp+20]		;dcut
	
	pop	ecx

	fldz				;buf1
	fldz				;buf0	buf1
	fldz				;phase	buf0	buf1
	;mov	ecx,[ABS(nsamples)]
.loop_sample:

	fadd	dword [ebp+12]		;phase+fVal	buf0	buf1
	
	push	eax
	fist	dword [esp]		;phase	buf0	buf1
	fild	word [esp]		;phase	phase	buf0	buf1
	pop	eax
	fmul	dword [ABS(fcnt2_65)]	;store	phase	buf0	buf1
					
	mov	al,[esi+perxxor.wavetype]
	or	al,al
	jz	.outtaSpecialCases
					;replace current value
	fstp	st0			;phase	buf0	buf1
	fld	st0			;phase phase	buf0	buf1
	;fld	dword [ebp]		;phase phase	buf0	buf1
	fmul	dword [ABS(fcnt2PId44100)]	;phase*214..	phase	buf0	buf1
	fsin				;store	phase	buf0	buf1

	cmp	al,2
	jne	.outtaSpecialCases
	
	fld1				;1	store	phase	buf0	buf1
	fldz				;0	1	store	phase	buf0	buf1
	fcomip	st2			;1	store	phase	buf0	buf1
	jc	.positive			;test this!!!	
	fchs				;-1	store	phase	buf0	buf1
.positive
	fxch	st1			;store	1/-1	phase	buf0	buf1
	fstp	st0			;store	phase	buf0	buf1
.outtaSpecialCases:
					;store	phase	buf0	buf1
	movzx	eax,byte [esi+perxxor.randgain]		;unsigned
	push	eax
	fild	dword [esp]		;rgain	store	phase	buf0
	pop	eax	
	call	myRandFloat		;[0..1]	rgain	store	phase	buf0	buf1
	fmulp	st1,st0			;rand	store	phase	buf0	buf1
	fidiv	word [ABS(icnt127)]	;r/127	store	phase	buf0	buf1
	faddp	st1,st0			;store+rand	phase	buf0	buf1
	
;	push	dword [ebp+24]		;f
;	pop	dword [ebp+12]		;lfc
	
	fld	dword [ebp+8]		;q	store+rand	phase	buf0	
	fld1				;1	q		store+rand	phase	buf0	buf1
	fsub	dword [ebp+04]		;1-lfc	q		store+rand	phase	buf0	buf1
	fdivp	st1,st0			;1/1-lfc		store+rand	phase	buf0	buf1
	fadd	dword [ebp+08]		;1/(1-lfc)+q		store+rand	phase	buf0	buf1
	fstp	dword [ebp]		;store+rand	phase	buf0	buf1
					;lfb

	fsub	st0,st2			;store-buf0	phase	buf0	buf1
	fld	st2			;buf0		store-buf0	phase	buf0	buf1
	fsub	st0,st4			;buf0-buf1	store-buf0	phase	buf0	buf1
	;fsub	dword [ebp+8]		
	fmul	dword [ebp]		;(b0-b1)lfb	store-buf0	phase	buf0	buf1
	faddp	st1,st0			;(b0-b1)lfb+store-buf0		phase	buf0	buf1
	fmul	dword [ebp+04]		;lfc (X)	phase		buf0	buf1
	fadd	st0,st2			;lfc(X)+buf0	phase		buf0	buf1
	fstp	st2			;phase		buf0	buf1
					;buf0
	
	fld	st1			;buf0			phase	buf0	buf1
	fsub	st0,st3			;buf0-buf1		phase	buf0	buf1
	fmul	dword [ebp+04]		;lfc(b0-b1)		phase	buf0	buf1
	faddp	st3,st0			;phase	buf0	buf1+lfc(b0-b1)
	fld	st2			;store	buf0	buf1+lfc(b0-b1)
	;fst	dword [ebp+8]		;buf1
					;store			phase	buf0	buf1
	;fstp	dword [ebp+20]		;store			
	
	fld	dword [ebp+04]		;f		buf0	buf1
	fadd	dword [ebp+20]		;dcut		buf0	buf1
	fstp	dword [ebp+04]		;f		buf0	buf1
	
	fld	dword [ebp+08]		;q		buf0	buf1
	fadd	dword [ebp+24]		;dres		buf0	buf1
	fstp	dword [ebp+08]		;q		buf0	buf1
	
	;fld	dword [ebp+20]		;store		buf0	buf1
	fmul	dword [ebp+28]		;amp		buf0	buf1
	;fstp	dword [ebp+20]		;store		buf0	buf1
	
	fld	dword [ebp+12]		;fVal		buf0	buf1
	fmul	dword [ebp+16]		;fdVal		buf0	buf1
	fstp	dword [ebp+12]		;fVal		buf0	buf1
	
	;fdVal *= 1.f+p->ddFreq / (256.f*65536.f*256.f); //*65536.f);
	
	fld	dword [ebp+28]		;amp		buf0	buf1
	fadd	dword [ebp+32]		;damp		buf0	buf1
	fstp	dword [ebp+28]		;amp		buf0	buf1
	
	;fld	dword [ebp+20]		;store
	fimul	word [ABS(icnt127)]
	
	push	eax
	fistp	dword [esp]
	pop	eax
	cmp	eax,127
	jle	.okRangeUp
	mov	eax,127
	
.okRangeUp:
	cmp	eax,-127
	jge	.okRangeDown
	mov	eax, -127
.okRangeDown:
	add	eax,127
	stosb
		
	dec	ecx
	jnz	.loop_sample

	finit				;Reset fpu
	
	ret
	
	;icnt1Mb		dd	1048576
	;fcnt_inv16M	dd	0.00000000023283064365386962890625
	fcnt_inv16M	dd	0.00000095367431640625
	icnt32k		dw	32767
	icnt100		dw	100
	;fcnt0d01	dd	0.01
	fcnt0d0019	dd	0.0019274376417233560090702947845805
	fcnt2PId44100	dd 	1.4247585730565955729989312395825e-4


	icnt127		dw	127
	fcnt2_65	dd	0.000030517578125

%if 0
	float		fVal = p->freqIni;
	float		fdVal = 1.f + p->dFreq / (16.f*256.f*256.f); //65536.f;

	float		phase;

	volatile float		amp = p->ampIni/100.f;
	volatile float		damp = (0.01f*p->dAmp) / p->nSamples;

	volatile float buf0 = 0.f, buf1 = 0.f;
	volatile float lfc, lfb;

	float f = p->cutIni*85.f / 44100.f;
	float q = p->resIni / 100.f;

	volatile float dres = (0.01f*p->dRes) / p->nSamples;
	volatile float dcut = (p->dCut*85.f / 44100.f) / p->nSamples;


	for (int i = 0; i < p->nSamples; i++)
		{

		phase += fVal;

		signed short uVal;
		int	iVal;

		iVal = phase;

		uVal = iVal & 0xffff;

		fb [i] = 2.f*uVal/65536.f; //2.f*sVal/65536.f;

		if (p->wType)
				fb [i] = sin (phase*2*3.1415/44100.f);

		if (p->wType == 2)
			{
				if (fb [i] > 0)		fb [i] = 1.f;
				else	fb [i] = -1.f;
			}


	fb [i] += p->bRandGain*(-1 +(rand ())/(0.5f*RAND_MAX))/127.f;

		
//		fVal += fdVal;
//		fdVal += p->ddFreq / (65536.f*256.f); //*65536.f);

	lfc = f;
	lfb = q + q / (1.0 - lfc);


			float val = fb [i];
			buf0 += lfc * (val - buf0 + lfb * (buf0 - buf1));
			buf1 += lfc * (buf0 - buf1);

			fb [i] = buf1; //(buf1 - (buf1*buf1*buf1)/6)*65536.f;


			f += dcut;
			q += dres;

		fb [i] *= amp;

		fVal *= fdVal;
		fdVal *= 1.f+p->ddFreq / (256.f*65536.f*256.f); //*65536.f);

		amp += damp;
		}
	}





;**************************************************************************************************** old








	
	float		fVal = p->freqIni;
	float		fdVal = 1.f + p->dFreq / (16.f*256.f*256.f); //65536.f;

	float		phase;

	volatile float		amp = p->ampIni/100.f;
	volatile float		damp = (0.01f*p->dAmp) / p->nSamples;

	volatile float buf0 = 0.f, buf1 = 0.f;
	volatile float lfc, lfb;

	float f = p->cutIni*85.f / 44100.f;
	float q = p->resIni / 100.f;


	volatile float dres = (0.01f*p->dRes) / p->nSamples;
	volatile float dcut = (p->dCut*85.f / 44100.f) / p->nSamples;


	for (int i = 0; i < p->nSamples; i++)
		{

		phase += fVal;

		signed short uVal;
		int	iVal;

		iVal = phase;

		uVal = iVal & 0xffff;

		fb [i] = 2.f*uVal/65536.f; //2.f*sVal/65536.f;

		if (p->wType)
				fb [i] = sin (phase*2*3.1415/44100.f);

		if (p->wType == 2)
			{
				if (fb [i] > 0)		fb [i] = 1.f;
				else	fb [i] = -1.f;
			}


	fb [i] += p->bRandGain*(-1 +(rand ())/(0.5f*RAND_MAX))/127.f;

		
	lfc = f;
	lfb = q + q / (1.0 - lfc);

			float val = fb [i];
			buf0 += lfc * (val - buf0 + lfb * (buf0 - buf1));
			buf1 += lfc * (buf0 - buf1);

			fb [i] = buf1; //(buf1 - (buf1*buf1*buf1)/6)*65536.f;


			f += dcut;
			q += dres;

		fb [i] *= amp;

		fVal *= fdVal;
		fdVal *= 1.f+p->ddFreq / (256.f*65536.f*256.f); //*65536.f);

		amp += damp;
		}
	}
	
	;convertir
	
		float		fVal;

		fVal = fSampleBuffer [i];

		if (fVal > 1.f)		fVal = 1.f;
		else 
		if (fVal < -1.f)	fVal = -1.f;

		bSampleBuffer [i] = fVal * 127.f + 127.f;

%endif