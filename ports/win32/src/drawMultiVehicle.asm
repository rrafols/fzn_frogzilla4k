
	xor	ebx,ebx		;ebx = xcpos
.nj_loop_dv:
	xor	esi,esi		;esi = zcpos
.ni_loop_dv:
	
	fld	dword [ABS(dtime0)]
	fadd	st0,st0			;Dtime0 * cantonades
	push	esi
	fiadd	dword [esp]
	pop		esi
	push	ebx
	fiadd	dword [esp]
	pop		ebx
	fistp	dword [ABS(holdrand)]

	call	myRandFloat
	fabs
	fadd	st0,st0
	fadd	st0,st0
	fistp	dword [ABS(ncars)]
	dec	dword [ABS(ncars)]
;	mov	dword [ABS(ncars)],2

	xor	ecx,ecx
.cedge:	

	pushad
	push	byte 0
	push	dword #1.0#
	push	byte 0
	push	dword #90.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	popad

	xor	edi,edi
.cepos:

	pushad


	;glTranslatef(0.1f-BL_DISP*(xcpos-nj/2),0,caroffsets[cepos*4+cedge]*BL_DISP*cantonades+carsep*(carnum/2-cepos)-BL_DISP*(zcpos-ni/2));


	;caroffsets[cepos*4+cedge]*BL_DISP*cantonades+carsep*(carnum/2-cepos)-BL_DISP*(zcpos-ni/2));

;	mov	dword [ABS(temp)],ecx


	mov		eax,edi
	shl		eax,2
	add		eax,ecx ;[ABS(temp)]			;temp = cedge
	fld		dword [ABS(caroffsets) + eax * 4]
	fadd	st0,st0

	mov		eax,esi
	sub		eax,(CITY_WIDTH + CANTONADES) / 2 - 1      ;citywidth +cantonades / 2 al C
	push	eax
	fild	dword [esp]		;zcpos - ni/2
	pop		eax
	fsubp	st1,st0

	fmul	dword [ABS(fcnt0d24)]

;	fld		dword [ABS(fcnt1d5)]			
	fld1
	push	edi
	fisub	dword [esp]
;	pop		edi
	fmul	dword [ABS(fcnt0d05)]
	faddp	st1,st0							

;	push	eax
	fstp	dword [esp]

	push	byte 0
	
	mov		eax,ebx
	sub		eax, (CITY_HEIGHT + CANTONADES) / 2 - 1  ; citylong + 2 / 2 -1 al C
	push	eax
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d24)]
	fsubr	dword [ABS(fcnt0d1)]
	fstp	dword [esp]

	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	
	;glRotatef(carrotate*myRandFloat(),0,1,0);

	push	byte 0
	push	dword #1.0#
	push	byte 0
	call 	myRandFloat
	fmul	dword [ABS(carrotate)]
	push	byte 0
	fstp	dword [esp]
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	
	
;	mov		eax,#0.02#
;	push	eax
;	push	eax
;	push	eax
;	INVOKER	ebp+oglImports.glScalef
	
	
	pushad
	call	myRandFloat
	fabs

	fimul	word [ABS(icnt7)]
	;fadd	st0,st0
	;fadd	st0,st0
	;fadd	st0,st0
	push	esi
	fistp	dword [esp]
	pop	esi
;	inc	esi
	;mov	esi,1
	%include "../build/drawVehicle.asm"
	;call	drawVehicle
	popad

	;drawVehicle(1+(int)(4*randomaizer((float)(zcpos+dtime0*cantonades),(float)cepos,(float)xcpos)));
	
	;call	dword [ebp + oglOrdinal.glPopMatrix]
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	popad
	
	inc	edi
	cmp	edi,[ABS(ncars)]
	jl	.cepos

	inc	ecx
	cmp	ecx,4
	jl	.cedge
	
	inc	esi
	cmp	esi,CITY_WIDTH + CANTONADES		; citylong+2 al C
	jl	.ni_loop_dv
	
	inc	ebx
	cmp	ebx,CITY_HEIGHT				; citywidth+2 al C
	jl	.nj_loop_dv
	
%if 0	
void drawMultiVehicle (int ni, int , float time)
{
	int ncars;
	for (xcpos=0;xcpos<nj;xcpos++)
		for (zcpos=0;zcpos<ni;zcpos++)
		{
			ncars=(int)(0.3+sin(zcpos+dtime0*cantonades)+cos(xcpos));
			for (cepos=0;cepos<=ncars;cepos++)
				for (cedge=0;cedge<4;cedge++)
				{
					glPushMatrix();
					glRotatef(90.f*cedge,0.f,1.f,0.f);
					glTranslatef(0.1f-BL_DISP*(xcpos-nj/2),0,caroffsets[cepos*4+cedge]*BL_DISP*cantonades+carsep*(carnum/2-cepos)-BL_DISP*(zcpos-ni/2));
//					glScalef(0.02f,0.02f,0.02f);
					glRotatef(carrotate*(float)sin(cedge+ncars+cepos),0,1,0);
//					drawVehicle(2+(unsigned char)(0.5f+1.1f*sin(zcpos-2+dtime0*cantonades)+cos(xcpos+3)));
					drawVehicle(1+(int)(4*randomaizer((float)(zcpos+dtime0*cantonades),(float)cepos,(float)xcpos)));
					glPopMatrix();
					
				}
		}
}
%endif