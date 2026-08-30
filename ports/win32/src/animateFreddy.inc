	
	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
%if 0	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	push	dword #-90.0#
	call	dword [ebp + oglOrdinal.glRotatef]
%endif
	push	byte 0
	
	fld	dword [ABS(FreddyAlt)]
	fadd	dword [ABS(fcnt0d4)]
	push	eax
	fstp	dword [esp]

	fld	dword [ABS(FreddyPos)]
;	fchs
	push	eax
	fstp	dword [esp]

	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	
	call	drawFrog
	
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glPopMatrix]