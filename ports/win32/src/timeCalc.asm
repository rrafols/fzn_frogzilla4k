;********************************************************************************* timecalc
.timeCalc:
	xor		eax,eax
	mov		[ABS(FreddyPos)],eax
	
	mov		eax,#1000.0#
	mov		[ABS(FreddyAlt)],eax
	
	fld		dword [ABS(ts)]

;	mov	eax,DESTRUCT_TIME
;	push	eax
;	fsub	dword [esp]			;%f
;	pop		eax

	fisub	word [ABS(icnt3150)]
;	push	byte 0
;	fst		dword [esp]
;	pop		eax
;	add		eax,eax

	fldz
	fcomip	st1
	jl		.noDestruction


;	and		eax,0x80
;	fst		dword [ABS(temp)]
;	and		byte [ABS(temp) + 3],0x80
;	jc		.noDestruction
	
	fidiv	word [ABS(icnt100)]
	fstp	dword [ABS(delta)]
	
	fld	dword [ABS(delta)]
	fsub	dword [ABS(fcnt0d5)]
;	fistp	dword [ABS(FreddyBPos)]
;	fild	dword [ABS(FreddyBPos)]
;	fstp	dword [ABS(FreddyBPos)]

	push	byte 0
	fist	dword [esp]
	fild	dword [esp]
	pop	eax

	fld	st0
	fsubr	dword	[ABS(delta)]
	
;	fld	dword [ABS(delta)]
;	fsub	dword [ABS(FreddyBPos)]
	fadd	st0,st0
	call	clampminmaxz1
	faddp	st1,st0
;	fadd	dword [ABS(FreddyBPos)]
;	fstp	dword [ABS(FreddyBPos)]
	
;	fld	dword [ABS(FreddyBPos)]
;	fsub	dword [ABS(fcnt5d5)]
	fisub	word [ABS(icnt8)]			;citylong/2-2
;	fisub	word 8
	fmul	dword [ABS(fcnt0d24)]
	fstp	dword [ABS(FreddyPos)]
	
	fild	word [ABS(icnt1000)]			;max
	fldz						;min
	fld		dword [ABS(delta)]
	fadd	st0,st0
	fldpi
	fmulp	st1,st0
	fsin
	fmul	dword [ABS(fcnt0d4)]
	call	clampminmax
	fst		dword [ABS(FreddyAlt)]
	
;	fldz					;no se si cal
.noDestruction
	fstp	st0
	
	;carrotate=clampminmax((time-frozetime+20.0f)*1.5f,0.0f,30.0f);
	;offset=clampminmax(time,0.0f,frozetime);
	;dtime0=(float)floor(offset*carvel/cantonades);
	;dtime1=offset*carvel/cantonades-dtime0;
	
	fild	word [ABS(icnt30)]
	fldz
	
	fld		dword [ABS(ts)]
	fisub	word [ABS(icnt2850)]
	fiadd	word [ABS(icnt20)]
	fmul	dword [ABS(fcnt1d5)]
	call	clampminmax
	fstp	dword [ABS(carrotate)]
	
	fild	word [ABS(icnt2850)]
	fldz
	fld		dword [ABS(ts)]
	call	clampminmax
	fstp	dword [ABS(doffset)]
	
	fld		dword [ABS(doffset)]
	fmul	dword [ABS(fcarvelcant)]
	fld     st0

	fsub	dword [ABS(fcnt0d5)]
	fistp	dword [ABS(dtime0)]
	fild	dword [ABS(dtime0)]
	fst		dword [ABS(dtime0)]
	fsubp	st1,st0

;	fld		dword [ABS(doffset)]
;	fmul	dword [ABS(fcarvelcant)]

;	fsub	dword [ABS(dtime0)]
	fstp	dword [ABS(dtime1)]
	

	xor		ebx,ebx
	
	xor		edx,edx
.cepos_loop

	xor		ecx,ecx
.cedge_loop:

	push	edx
	fild	dword [esp]
	pop		edx
	
	fmul	dword [ABS(fcarfasevelcant)]
;	fmul	dword [ABS(fcarvelcant)]
	fsubr	dword [ABS(dtime1)]
;	fstp	dword [ABS(doffset)]
	
	mov	eax,ecx
	and	eax,1
	jnz	.cedge_pair
	
;	fld		dword [ABS(doffset)]
	fsub	dword [ABS(fcnt0d5)]
.cedge_pair:
	fstp	dword [ABS(doffset)]
	
	fld	dword [ABS(doffset)]
	fdiv	dword [ABS(fcnt0d4)]
;	fld	st0
;	fsub	dword [ABS(fcnt0d5)]
;	fistp	dword [ABS(semoffsets) + ebx * 4]
	
;	fimul	word [ABS(icnt30)]
	call	clampminmaxz1
	fstp	dword [ABS(caroffsets) + ebx * 4]
%if 0	
	mov	byte [ABS(semoffsets) + ebx],2

	fld	dword [ABS(doffset)]
	fstp	dword [ABS(temp)]
	and	byte [ABS(temp) + 3], 0x80
	jnz	.offsetNeg
	
	fld	dword [ABS(doffset)]
	fimul	word [ABS(icnt1000)]
	fistp	dword [ABS(temp)]
	
;			if (offset>0.0f)
;			{
;				if (offset<0.35f) semoffsets[toffset]=0;
;				else if (offset<0.5f) semoffsets[toffset]=1;
;			}
	
	mov	eax,[ABS(temp)]
	cmp	eax,3500
	jge	.noSem1
	
	mov	byte [ABS(semoffsets) + ebx],0
	jmp	.noSem2
.noSem1
	cmp	eax,5000
	jge	.noSem2
	
	mov	byte [ABS(semoffsets) + ebx],1
.noSem2
%endif
	
.offsetNeg:
	inc	ebx
	
	inc	ecx
	cmp	ecx,4
	jl	.cedge_loop
	
	inc	edx
	cmp	edx,CAR_NUM
	jl	.cepos_loop
	
;	toffset=0;
;	for (cepos=0;cepos<carnum;cepos++)
;		for (cedge=0;cedge<4;cedge++)
;		{
;			offset=dtime1-cepos*carfase*carvel/cantonades;
;			if ((cedge&1)==1)	offset-=0.5f;
;			caroffsets[toffset]=clampminmax(offset/0.4f,0.0f,1.0f);
;			semoffsets[toffset]=2;
;			if (offset>0.0f)
;			{
;				if (offset<0.35f) semoffsets[toffset]=0;
;				else if (offset<0.5f) semoffsets[toffset]=1;
;			}
;			toffset++;
;		}
