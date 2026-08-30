; renderCub(0.008f,1.1f*citywidth*BL_DISP,citylong*BL_DISP*1.1f, 0.f,-0.008f,0.f);
	push	dword #1.2#			; El tamany del terra depen de citylong i de citywidth :P
	push	dword #0.004#			
	push	dword #2.0#
	push	byte 0
	push	dword #-0.008#
	push	byte 0
	call	drawCubeTS

	xor	ebx,ebx
.ni_loop:
	xor	esi,esi
.nj_loop:
	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
	
	mov	eax,esi				;Al bucle esi va de 0 a citywidth
	sub	eax,CITY_WIDTH / 2		;citywidth /2
	push	eax
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d24)]
	fstp	dword [esp]
	
	push	byte 0

	mov	eax,ebx				;Al bucle ebx va de 0 a citylong
	sub	eax,CITY_HEIGHT / 2		;citylong / 2
	push	eax
	fild	dword [esp]
	fmul	dword [ABS(fcnt0d24)]
	fstp	dword [esp]
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!! Falta fer destruccio
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!	

	pushad
	fld	dword [ABS(ts)]
	fisub	word [ABS(icnt3150)]
	fmul	dword [ABS(fcnt0d05)]
	imul 	ebx,5
	push	ebx
	fild	dword [esp]
	pop	ebx
;	fadd	dword [ABS(fcnt1d25)]
	fiadd	word [ABS(icnt11)]
	fsubp	st1,st0
	fstp	dword [ABS(destruct)]
	mov	eax,esi
	sub	eax,CITY_WIDTH / 2		; aixo hauria de esser citywidth/2 pero fa com si fos citylong :P?
	cdq			; Valor absolut xungo by BP
	xor	eax,edx
	sub	eax,edx
	and	al,254
	jz	.doDestruct
	mov	dword [ABS(destruct)], 0
.doDestruct
	
;	fld	dword [ABS(ts)]
;	fmul	dword [ABS(fcnt0d005)]
;	fstp	dword [ABS(destruct)]
	call	myRandFloat
	fabs
	fimul	word [ABS(icnt7)]
	fld1
	faddp	st1,st0
	fistp	dword [ABS(height)]
	%include "../build/drawBlock.asm"
	;call	drawBlock
	popad
	
	;call	dword [ebp + oglOrdinal.glPopMatrix]
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	inc	esi
	cmp	esi,CITY_WIDTH			; bucle citywidth
	jl	.nj_loop
	
	inc	ebx
	cmp	ebx,CITY_HEIGHT			; bucle citylong
	jl	.ni_loop

%if 0
void drawBlock(int altura,float destruct) {
	int i,j,k;
	float anglea,angleb;

	
	renderCub(0.4f*0.02f,1.1f*0.13f,1.f*0.13f, 0.f,0.f,0.f);
	for (i=0;i<4;i++)
	{
		glPushMatrix();
		anglea=(destruct-altura*0.2f)*90.0f;
		if (anglea<0) anglea=0;
		if (anglea>80) anglea=80;
		glRotatef(90.0f*(i+1),0.f,1.f,0.f);
		for (j=0;j<=2;j++)
		{
			glPushMatrix();
			glTranslatef(-0.08f*(j-1)/2,0,0.06f);
			glRotatef(anglea,0,0,1);
			glScalef(0.05f,0.05f,0.05f);
			drawFarola();
			glPopMatrix();
		}
		glTranslatef(-0.06f,0,0.06f);
		glRotatef(anglea,0,0,1);
		glScalef(0.05f,0.05f,0.05f);
		drawSemafor(semoffsets[i]);
		glPopMatrix();
	}

	for (i = 0; i < altura; ++i) {
		glPushMatrix();

		glScalef(0.1f, 0.1f, 0.1f);
		glTranslatef(0.f,i*0.2f+0.2f, 0.f);

		if (i>0)
		{
			anglea=(destruct+(i-altura)*0.2f)*90.0f;
			angleb=(anglea-67)*0.01f;
			if (angleb>(0.3f*i+0.2f)) angleb=0.3f*i+0.2f;
			if (angleb>0.f)
				glTranslatef(0.f,-angleb, 0.f);
			if (anglea<0) anglea=0;
			if (anglea>67) anglea=67;
			glRotatef(i*90.f,0.f,1.f,0.f);
			glRotatef(anglea,1.f,0.f,0.f);
		}
		glTranslatef(0.f,0.3f*i, 0.f);
		
		glColor3f(0.15f,0.15f,0.55f);
		renderCub(0.4f,1.1f,1.1f, 0.f,0.f,0.f);

		glColor3f(0.1f,0.05f,0.4f);
		renderCub(0.2f,1.f,1.f, 0.f,0.2f,0.f);
		for (j=0;j<=4;j++)
			for (k=0;k<4;k++)
			{
				glRotatef(90.f*k,0.f,1.f,0.f);
				if (((float)(sin(i*32.f)+cos(j*15.f)+sin(altura*12.f))>0)&(anglea<=0.0f))
					glColor3f(1,1,1);
				else glColor3f(0,0,0);
				renderCub(0.14f,0.14f,0.02f,0.55f,0,(j-2)*0.18f);
			}
		glPopMatrix();
	}
}
%endif