

	;glColor3f(0.2f,0.2f,0.25f)
	push	dword ABS(colorBlock)
	INVOKAH	glColor4ubv,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glColor4ubv]

	;renderCub(0.4f*0.02f,1.1f*0.13f,1.f*0.13f, 0.f,0.f,0.f);
	push	dword #0.065#
	push	dword #0.002#
	push	dword #0.0715#

	push	byte 0
	push	byte 0
	push	byte 0
	call	drawCubeTS
	
	fild	word [ABS(icnt30)]
	fldz
	fld	dword [ABS(destruct)]
	fisub	dword [ABS(height)]
	fimul	word [ABS(icnt8)]
	call	clampminmax
	fstp	dword [ABS(tmpd2)]
	
	

	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	%if 0
	anglea=(destruct-altura*0.2f)*90.0f;
		if (anglea<0) anglea=0;
		if (anglea>80) anglea=80;
	
	fild	dword [ABS(altura)]
	fmul	dword [ABS(fcnt0d2)]
	fsubr	dword [ABS(destruct)]
	fimul	dword [ABS(icnt90)]
	%endif
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
	xor	ebx,ebx			;bucle de 4
.i_loop
	push 	byte 0
	push 	dword #1.0#
	push 	byte 0
	push 	dword #90.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp

	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;!!! Hack per reduir les crides, tenint en compte que NO HI HA SEMAFOR
	;!!! Pain
	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
	push 	dword #0.06#
	push 	byte 0
	push 	dword #0.03#
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	xor	edi,edi
.j_loop:
	pushad

	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword [ABS(tmpd2)]			;anglea
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
;	call	drawFanal
	%include "../build/drawFanal.asm"

	push	byte 0
	push	byte 0
	push	dword #-0.03#
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]

	popad
	inc	edi
	cmp	edi,2
	jle	.j_loop
	
	pushad
;	movzx	esi,byte [ABS(semoffsets) + ebx]
;	call	drawSemaf
	;call	dword [ebp + oglOrdinal.glPopMatrix]
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	popad
	
	inc	ebx
	cmp	ebx,4
	jne	.i_loop

;!!!!!!!!!!!!!!!!!!!!!!!!
;!! Parkecillus. Eliminats per el BP
;!!!!!!!!!!!!!!!!!!!!!!!!

	
%if 0
	cmp	dword [ABS(height)],1		;altura!!
	jne	.noZeroHeight
	
	push	dword ABS(greenZoneColor)
	call	dword [ebp + oglOrdinal.glColor4ubv]
	
	;if (altura==0)	{
	;	glColor3ubv(BlockColors+15);
	;	renderCub(0.008f,0.1f,0.1f, 0.f,0.004f,0.f);
	;}
	
	
	push	dword #0.1#
	push	dword #0.008#				;WOWOWOWOWOWO!S
	push	dword #0.1#

	push	dword #0.004#
	push	byte 0
	push	byte 0
	call	drawCubeTS

	
	push	dword ABS(edifCol)
	call	dword [ebp + oglOrdinal.glColor4ubv]
	
	jmp	.noBlock
.noZeroHeight:
%endif

	xor	ebx,ebx
.i_loop2:
	pushad
;	call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp

;	Si, BP & Ufix, teoricament ocupa menys fent el inc eax, pero a la practica NO
	
	push	byte 0

%if 0
	push	ebx
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d02)]
	fadd	dword [ABS(fcnt0d02)]
	fstp	dword [esp]
	push	byte 0
	call	dword [ebp + oglOrdinal.glTranslatef]
%endif

	fild	word [ABS(icnt67)]
	fldz
	fld	st1
	fld	dword [ABS(destruct)]
	push	ebx
	fiadd	dword [esp]
	pop	ebx
	fisub	dword [ABS(height)]
	fimul	word [ABS(icnt18)]
	fst	dword [ABS(tmpd2)]
	fsubrp	st1,st0
;	fisub	word [ABS(icnt67)]
	fmul	dword [ABS(fcnt0d001)]
	fstp	dword [ABS(tmpd)]
	fld	dword [ABS(tmpd2)]
	call	clampminmax
	fstp	dword [ABS(tmpd2)]
	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	mov	eax,ebx
	imul	eax,byte 90
	push	eax
	fild	dword [esp]
	fstp	dword [esp]
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword [ABS(tmpd2)]
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
; errr, no faltaria un push 0?!?!?!?	
;	push	byte 0
	push	ebx
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d05)]
	fadd	dword [ABS(fcnt0d02)]
	fstp	dword [esp]
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	dword ABS(edifCol)
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	push	dword #0.055#
	push	dword #0.02#
	push	dword #0.055#
	push	byte 0
	push	byte 0
	push	byte 0
	call	drawCubeTS
	
	push	dword ABS(edifCol + 4)
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	push	dword #0.05#
	push	dword #0.01#
	push	dword #0.05#
	push	byte 0
	push	dword #0.02#
	push	byte 0
	call	drawCubeTS
	
	xor	ebx,ebx
.j_loop2:
	push byte 0
	push dword #1.0#
	push byte 0
	push dword #90.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	xor	esi,esi
.k_loop:
	pushad
%if 0	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	mov	eax,esi
	imul	eax,90
	push	eax
	fild	dword [esp]
	fstp	dword [esp]
	call	dword [ebp + oglOrdinal.glRotatef]
%endif
	
	mov	edi,ABS(zerov)
	call	myRandFloat

	fldz
	fcomip	st1
	jnc	.okWindow
	fstp	st0
	fld	dword [ABS(tmpd2)]
	fldz
	fcomip	st1
	jc	.okWindow
	mov	edi,ABS(onev)
.okWindow:
	fstp	st0
	push	edi
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	
	push	dword #0.007#
	push	dword #0.007#
	push	dword #0.001#
	
	mov		eax,esi
	dec		eax
	dec		eax
	push	eax
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d018)]
	fstp	dword [esp]
	push	byte 0
	push	dword #0.055#
	call	drawCubeTS
	popad
	
	inc	esi
	cmp	esi,4
	jle	.k_loop

	inc	ebx
	cmp	ebx,4
	jl	.j_loop2

	;call	dword [ebp + oglOrdinal.glPopMatrix]
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	popad
	inc	ebx
	cmp	ebx,[ABS(height)]		;altura!!
	jne	.i_loop2
.noBlock: