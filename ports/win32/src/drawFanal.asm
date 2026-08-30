;*************************************************************************************************************************
; DrawFanal
;*************************************************************************************************************************
;drawFanal:
	push	dword ABS(fanal)
;	call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	
	push	dword #0.0012#
	push	dword #0.02#
	push	dword #0.0012#
	push	byte 0
	push	dword #0.02#
	push	byte 0
	call	drawCubeTS

	push	dword ABS(onev)
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	
	push	dword #0.003#
	push	dword #0.003#
	push	dword #0.003#

	push	byte 0
	push	dword #0.04#
	push	byte 0
	call	drawCubeTS
	
;	ret
