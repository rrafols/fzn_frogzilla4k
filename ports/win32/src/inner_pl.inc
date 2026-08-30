%define	NCHANNELS	8

threadMain:	

	xor	ebx,ebx
	xor	eax,eax			;order
	push	ebx			;cuidadin con la pila... realment es com un "push ecx"
	dec	ebx			;row=-1
	jmp	near mainPlayerFirst

mainPlayer:
	push	eax
	;call	dword [ABS(funcAddress3) + kernelOrdinal.GetTickCount]
	INVOKAH	GetTickCount, kernelOrdinal, funcAddress3
	sub	eax,[ABS(oldTickCount)]
	push	eax
	fild	dword [esp]
	pop	eax	
	pop	eax
;	pop	ecx			; ecx no es machaca amb getTickCount... crec
;	inc	ecx
;	push	ecx
	inc	dword [esp]
	fild	dword [esp]
	fmul	dword [ABS(tickfactor)]			;tsideal
	fdivp	st1,st0
	fstp	dword [ABS(timeDivider)]
mainPlayerFirst:
	inc	ebx
	cmp	ebx, byte 12
	jne	.okRow
	xor	ebx,ebx
	inc	eax
.okRow:
;	cmp	eax,63
;	jge	exitIntro
	
.okOrder
	push	eax
	
	
	mov	[ABS(row)],ebx
	mov	[ABS(order)],eax

	movzx	eax,byte [eax+ABS(orderList)]		;eax=order
	;movzx	eax,al
	shl	eax,3				;3 si 8 canals
						;2 si 4 canals
	mov	ebp,eax


	xor	eax,eax	
	mov	ecx, NCHANNELS
.loopCh:
	pushad

	add	eax,ebp				;eax=order+i
		
	movsx	eax,byte [eax+ABS(patternList)]
	;movsx	eax,al
							
	or	eax,eax
	js	near .noChannel
		
	mov	esi,ABS(channelList)
	imul	eax,25
	
	movzx	edi,byte [esi+eax]
	mov	edi,[edi*4+ABS(dsamples)]	;edi = dsoundbuffer

	add	eax,ebx		;[ABS(row)]
	inc	eax		;skippar el byte del numero de sample
	
	mov	bl,[esi+eax+12]		;tone port		canviar!!
	mov	[ABS(tone)],bl
	
	mov	bl,[esi+eax]			;bl=note
	or	bl,bl
	jz	.noChannel
	mov	bh,bl
	and	bl,0x0f	
	movzx	edx,bl
	dec	edx
		
	movzx	eax,bh
	shr	eax,4
	and	al,0x03

	shr	bh,6
	and	bh,0x03
	movzx	ebx,bh
	;mov	ebx,[ebx*4+ABS(vols)]	
	;push	ebx				;push volume!	
	push	dword [ebx*4+ABS(vols)]
	
		
	add	eax,byte 3	;+5		;3 octaves up (min octave)
	
	imul	eax,byte 12
	add	eax,edx
	
	mov	ebx,dword [edi]
	xor	esi,esi
	
	cmp	dx,0xffff
	je	.NoteOn
	
	cmp	dx,0x000e
	je	.NoteCut
	
	;mov	eax,[eax*4+ABS(freqtable)]
	;push	eax
	push	dword [eax*4+ABS(freqtable)]
	push	edi

	;cmp	byte [ABS(tone)],1		;TonePortamento!!
	dec	byte [ABS(tone)]
	je	.TonePort
	
	push	edi
	call	dword [ebx+72]		;.Stop
	
	push	esi
	push	edi
	call	dword [ebx+52]		;.SetCurrentPosition	
	
	
					; frequency (pushed)
					; soundbuffer (pushed)	
.TonePort:
	call	dword [ebx+68]		;.SetFrequency	

					;volume is pushed :)
.NoteOn:
	push	edi
	call	dword [ebx+60]		;.SetVolume

	push	esi
	push	esi
	push	esi	
	push	edi
	call	dword [ebx+48]		;.Play	
.noChannel:			
	popad
	inc	eax
	dec	ecx
	jnz	near .loopCh	

;	push	dword [ABS(milisperrow)]
	push	dword 160
	push	dword [ABS(thH)]
	;call	dword [ABS(funcAddress3) + kernelOrdinal.WaitForSingleObject]
	INVOKAH	WaitForSingleObject, kernelOrdinal, funcAddress3

	pop	eax
	jmp	near mainPlayer

.NoteCut:
	pop	eax
	;mov	eax,-10000
	;push	eax
	push 	-10000
	push	edi
	call	dword [ebx+60]		;.SetVolume
	
	push	edi
	call	dword [ebx+72]		;.Stop	
		
	push	esi
	push	edi
	call	dword [ebx+52]		;.SetCurrentPosition	
	jmp	short .noChannel