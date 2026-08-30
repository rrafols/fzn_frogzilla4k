;*************************************************************************************************************************
; DrawVehicle
;*************************************************************************************************************************
.drawVehicle:

	shl	esi,2
	add	esi,ABS(carColors)
	push	esi
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
		
;renderCub(0.005000,0.020000,0.012200,0.000000,0.000000,0.000000);


%if 0
	sub	  esp, 16*4
	mov   edi, esp
	mov   esi, ABS(VehicleCoords)
	mov   ecx, 16
	rep   movsd
%endif
	push  dword #0.01#
	push  dword #0.0025#
	push  dword #0.0061#
	push	byte 0
	push	byte 0
	push	byte 0

	call	drawCubeTS

;renderCub(0.000600,0.008000,0.012200,0.000000,0.005700,-0.002000);
	push  dword #0.004#
	push  dword #0.0003#
	push  dword #0.0061#
	push  dword #-0.002#
	push  dword #0.0057#
	push	byte 0
	call	drawCubeTS

;glRotatef(-28.647888,1.000000,0.000000,0.000000);
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #-28.65#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp

;renderCub(0.004388,0.002397,0.012200,0.000000,-0.004794,0.008776);

	push  dword #0.0012#
	push  dword #0.0022#
	push  dword #0.0061#
	push  dword #0.0088#
	push  dword #-0.0048#
	push  byte 0
	call	drawCubeTS
	
	push	dword ABS(clGlass)
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glColor4ubv]

;glRotatef(-22.918312,1.000000,0.000000,0.000000);

	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #-22.92#
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]

;renderCub(0.004826,0.006082,0.012000,0.000000,-0.000561,0.002511);

	push  dword #0.0030#
	push  dword #0.0024#
	push  dword #0.006#
	push  dword #0.0025#
	push  dword #-0.0006#
	push  byte 0
	call	drawCubeTS
%if 0
;glRotatef(74.484512,1.000000,0.000000,0.000000);

	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #74.49#

	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]

;renderCub(0.003257,0.001377,0.012000,0.000000,0.001101,-0.006980);

	push  dword #0.0007#
	push  dword #0.0016#
	push  dword #0.006#
	push  dword #-0.0070#
	push  dword #-0.0011#
	push  byte 0
	call	drawCubeTS

;glRotatef(-22.918312,1.000000,0.000000,0.000000);

	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #-22.92#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
%endif
;  cotxe simplificat
;glRotatef(51.57,1.000000,0.000000,0.000000);

	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #51.57#
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]

;renderCub(0.003000,0.008000,0.012000,0.000000,0.004000,-0.002000);

	push  dword #0.004#
	push  dword #0.0015#
	push  dword #0.006#
	push  dword #-0.002#
	push  dword # 0.004#
	push  byte 0
	call	drawCubeTS

	push	dword ABS(onev)
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	
	push  	dword #0.0015#
	push  	dword #0.0015#
	push  	dword #0.0015#
	push	dword #0.01#
	push	byte 0
	push  	dword #0.003#
	call	drawCubeTS
	
	push  	dword #0.0015#
	push  	dword #0.0015#
	push  	dword #0.0015#
	push	dword #0.01#
	push	byte 0
	push  	dword #-0.003#
	call	drawCubeTS
%if 0
	push  	dword #0.0015#
	push  	dword #0.0015#
	push  	dword #0.0015#
	push	dword #-0.01#
	push	byte 0
	push  	dword #0.003#
	call	drawCubeTS
	
	push  	dword #0.0015#
	push  	dword #0.0015#
	push  	dword #0.0015#
	push	dword #-0.01#
	push	byte 0
	push  	dword #-0.003#
	call	drawCubeTS
%endif
