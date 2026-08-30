	pushad	
	mov	edi,#1.0#
	mov	esi,#1.333#
	xor	ebx,ebx
	
	push	ebx	;z
	push	edi
	push	ebx
	push	edi
	push	ebx
	
	push	ebx	;z
	push	edi
	push	esi
	push	edi
	push	edi
	
	push	ebx	;z
	push	ebx
	push	esi
	push	ebx
	push	edi
	
	push	ebx	;z
	push	ebx
	push	ebx
	push	ebx
	push	ebx

	push	dword GL_QUADS
;	call	dword [ebp + oglOrdinal.glBegin]
;	call	dword [ebp + oglOrdinal.glTexCoord2f]
;	call	dword [ebp + oglOrdinal.glVertex3f]
;	call	dword [ebp + oglOrdinal.glTexCoord2f]
;	call	dword [ebp + oglOrdinal.glVertex3f]
;	call	dword [ebp + oglOrdinal.glTexCoord2f]
;	call	dword [ebp + oglOrdinal.glVertex3f]
;	call	dword [ebp + oglOrdinal.glTexCoord2f]
;	call	dword [ebp + oglOrdinal.glVertex3f]
;	call	dword [ebp + oglOrdinal.glEnd]
	INVOKAH	glBegin,oglOrdinal,ebp
	INVOKAH	glTexCoord2f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glTexCoord2f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glTexCoord2f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glTexCoord2f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glEnd,oglOrdinal,ebp
	popad