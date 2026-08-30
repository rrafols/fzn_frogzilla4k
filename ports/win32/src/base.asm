;%define WIN_XP
;%define CALL_BY_ORDINAL 
;%define GUARRADA_QUE_EL_PAIN_EM_MATARA

%include "macros.inc"
%include "opengl.inc"
%include "glext.inc"
%include "dsound.inc"
%include "winbase.inc"
%include "wingdi.inc"
%include "winuser.inc"	
%include "const.inc"
%include "pehdr.inc"
%include "oglOrdinal.inc"
%include "gluOrdinal.inc"
%include "invokah.inc"

%ifdef WIN_XP
	%include "gdiOrdinal.inc"
	%include "kernelOrdinal.inc"
	%include "userOrdinal.inc"
%else
	%include "gdiOrdinal2k.inc"
	%include "kernelOrdinal2k.inc"
	%include "userOrdinal2k.inc"
%endif

%define OPENGL_IMPORTS oglOrdinal_size / 4
%define GLU_IMPORTS gluOrdinal_size / 4
%define KERNEL_IMPORTS kernelOrdinal_size / 4
%define GDI_IMPORTS gdiOrdinal_size / 4
%define USER_IMPORTS userOrdinal_size / 4

%define 	NSAMPLES	8
%define 	FULLSCREEN	1
%define	SCREEN_WIDTH	640
%define	SCREEN_HEIGHT	480
%define	R2T_SIZE	256

%define CITY_WIDTH	9
%define CITY_HEIGHT	9
%define	CANTONADES	2
%define CAR_NUM		3
%define CAR_VELOCITY	#0.003#
;change fcarvelcant!!!
;%define CAR_SEPARATION	#0.05#
;%define CAR_PHASE	#25.0#
;%define	DESTRUCT_TIME	#3150.0#
;%define	FROZEN_TIME	#2850.0#
%define BL_DISP 	#0.24#

%define WAVE_FORMAT_PCM     	1

START_PROGRAM


		times	11	db	0

_OpenGL32Name	db	'OPENGL32.DLL',0
_glu32Name	db	'GLU32.DLL',0
_DSoundName	db	'DSOUND.DLL',0
_gdi32Name	db	'GDI32.DLL',0

	;	times	6	db	0
		
%ifndef GUARRADA_QUE_EL_PAIN_EM_MATARA
Pixelfd		dw	40		;size
		dw	1		;version
		dd	PFD_DRAW_TO_WINDOW + PFD_SUPPORT_OPENGL + PFD_DOUBLEBUFFER
		db	PFD_TYPE_RGBA	;iPixelType
		db	32		;ColorBits
		db	0,0,0,0,0,0	;Color+Shift bits (ignored)
		db	0,0		;Alpha bits & Shift bits (ignored)
		db	0		;No Accumulation Buffer
		db	0,0,0,0		;Accum Bits (ignored)
		db	32		;16 bits ZBuffer
		db	32		;No Stencil Buffer
		db	0		;No Auxiliary Buffer
		db	PFD_MAIN_PLANE	;iLayer Type
		db	0		;Reserved
		dd	0,0,0		;Layer Masks Ignored
%endif

bufdesc		dd	20		;size
		dd	DSBCAPS_PRIMARYBUFFER + DSBCAPS_STICKYFOCUS	;flags
		dd	0		;BufferBytes
		dd	0		;Reserved
		dd	0		;lpwfxFormat		
%ifdef WIN_XP
waveformat	dw	WAVE_FORMAT_PCM	;wFormatTag
		dw	1		;nChannels
		dd	44100		;SamplesPerSec
		dd	44100		;nAvgBytesPerSec
		dw	1		;nBlockAlign
		dw	8		;wBitsPerSample
		dw	0		;cbSize
%else
waveformat	dw	WAVE_FORMAT_PCM	;wFormatTag
		dw	2		;nChannels
		dd	22050		;SamplesPerSec
		dd	44100		;nAvgBytesPerSec
		dw	2		;nBlockAlign
		dw	8		;wBitsPerSample
		dw	0		;cbSize
%endif
_EntryPoint:	
	push	ebp
	
%ifdef CALL_BY_ORDINAL
	xor	edi,edi
	xor	esi,esi
	mov	ecx,5		;U
.loadLibs:
	push 	ecx
	
	push	dword [ABS(libNames) + esi * 4]
	INVOKER	ABS(LoadLibrary)
	
	xor	ebx,ebx
	movzx	ecx, word [ABS(libImports) + esi * 2]
.funcLoops:
	pushad
	
	push	ebx
	push	eax				;loadLibrary
	INVOKER	ABS(GetProcAddress)
	mov	[edi * 4 + ABS(funcAddress)],eax
	
	popad
	inc	ebx
	inc	edi
	loop	.funcLoops
	
	mov	dword [edi * 4 + ABS(funcAddress)],0
	inc	edi
	
	inc	esi
	pop	ecx
	loop	.loadLibs
%else
;	mov	edi,ABS(_IATStuff)
;	mov	eax,0x80000000
;	mov	ecx,4096
;	rep	stosd
%endif

	mov	edi,ABS(dmScreen)
%if FULLSCREEN	
	mov	dword [edi+ 36],148			;size
	mov	dword [edi+108],SCREEN_WIDTH			;width
	mov	dword [edi+112],SCREEN_HEIGHT			;height
	mov	dword [edi+104],32			;bits
	mov	dword [edi+40],DM_BITSPERPEL + DM_PELSWIDTH + DM_PELSHEIGHT
		
	;xor	eax,eax
	;push	eax
	push	byte 0
	push	dword _ImageBase
	push	byte 0
	push	byte 0
	push	dword SCREEN_HEIGHT
	push	dword SCREEN_WIDTH
	push	CW_USEDEFAULT
	push	CW_USEDEFAULT
	push	dword WS_POPUP | WS_VISIBLE |WS_CLIPSIBLINGS | WS_CLIPCHILDREN
	push	ABS(editName)
	push	ABS(editName)
	push	dword WS_EX_APPWINDOW
		
	push	byte 0		
	push	dword CDS_FULLSCREEN
	push	edi
	
	INVOKAH	ChangeDisplaySettingsA, userOrdinal, funcAddress5
	INVOKAH	ShowCursor, userOrdinal, funcAddress5
	INVOKAH	CreateWindowExA, userOrdinal, funcAddress5
;	call	dword [ABS(funcAddress5) + userOrdinal.ChangeDisplaySettingsA]
;	call	dword [ABS(funcAddress5) + userOrdinal.ShowCursor]
;	call	dword [ABS(funcAddress5) + userOrdinal.CreateWindowExA]
%else
	xor	eax,eax

	push	eax
	push	dword _ImageBase
	push	eax
	push	eax
	push	dword SCREEN_HEIGHT
	push	dword SCREEN_WIDTH
	push	CW_USEDEFAULT
	push	CW_USEDEFAULT
	push	dword WS_POPUP | WS_VISIBLE |WS_CLIPSIBLINGS | WS_CLIPCHILDREN
	push	ABS(editName)
	push	ABS(editName)
	push	dword WS_EX_APPWINDOW
	INVOKAH	CreateWindowExA,userOrdinal,funcAddress5
	;call	dword [ABS(funcAddress5) + userOrdinal.CreateWindowExA]
%endif

;	xor	ebx,ebx
	xchg	eax,edi

						;edi=hWnd
	mov	esi,ABS(dsound)
	
;	push	ebx
	push	byte 0
	push	esi
	push	byte 0
;	push	ebx
	INVOKER	ABS(DirectSoundCreate)
	
	mov	ebx,[esi]			;ebx -> [dsound]
	mov	esi,[ebx]			;esi -> [dsound->lpVtbl]
	push	dword DSSCL_EXCLUSIVE | DSSCL_PRIORITY
	push	edi				;hwnd
	push	ebx
	call	dword [esi+24]			;SetCooperativeLevel(dsound,hwnd,DSSCL_EXCLUSIVE | DSSCL_PRIORITY)	

	push	edi
	INVOKAH	GetDC,userOrdinal,funcAddress5
	;call	dword [ABS(funcAddress5) + userOrdinal.GetDC]
	
	xchg	eax,esi				;esi=hDC

%ifndef GUARRADA_QUE_EL_PAIN_EM_MATARA	
	push	esi
	mov	ebx,ABS(Pixelfd)
	
	push	ebx
	push	esi
	INVOKAH	ChoosePixelFormat,gdiOrdinal,funcAddress4
	;call	dword [ABS(funcAddress4) + gdiOrdinal.ChoosePixelFormat]
	
	push	dword ABS(Pixelfd)
	push	eax
	push	esi
	INVOKAH	SetPixelFormat,gdiOrdinal,funcAddress4
	;call	dword [ABS(funcAddress4) + gdiOrdinal.SetPixelFormat]
	pop	esi
%else
	push	byte 0
	push	byte 6
	push	esi
	INVOKAH	SetPixelFormat,gdiOrdinal,funcAddress4
	;call	dword [ABS(funcAddress4) + gdiOrdinal.SetPixelFormat]
%endif
	

	;push	ebp
	;mov	ebp,ABS(funcAddress)
	push	esi
	INVOKAH	wglCreateContext,oglOrdinal,funcAddress
	;call	dword [ebp + oglOrdinal.wglCreateContext]

	xchg	eax,ebx				;ebx=hRC
	
	push	ebx
	push	esi
	;INVOKER ABS(wglMakeCurrent)
	INVOKAH	wglMakeCurrent,oglOrdinal,funcAddress
	;call	dword [ebp + oglOrdinal.wglMakeCurrent]
	;pop	ebp
	
	mov	edi,[ABS(dsound)]	
	push	byte 0
	push	dword ABS(dprimary)
	push	dword ABS(bufdesc)
	push	edi
	mov	ebx,[edi]
	call	dword [ebx+12]			;CreateSoundBuffer(dsound,&bufdesc,&dprimary,NULL)	


;	mov	edi,[ABS(dprimary)]
;	mov	ebx,[edi]
;	push	dword ABS(waveformat)
;	push	edi
;	call	dword [ebx+56]			;SetFormat(dprimary,&waveformat);
	
	mov	edi,ABS(bufdesc)
	mov	[edi+4],dword DSBCAPS_CTRLDEFAULT + DSBCAPS_STICKYFOCUS + DSBCAPS_STATIC
	mov	[edi+16],dword ABS(waveformat)
	
	
	xor	eax,eax				;global pointer		
	mov	ebx,ABS(dsamples)
	mov	ecx,NSAMPLES
createSampleBuffers:

	pushad	
	mov	edx,eax
	shl	edx,4
	
	movzx	edx,word [edx+perxxor.nsamples+ABS(samples)]
	shl	edx,4		;einoneoien?!?!?
	mov	[edi+8],edx
		
	mov	edi,[ABS(dsound)]
	push	byte 0
	push	dword ebx
	push	dword ABS(bufdesc)
	push	edi
	mov	ebx,[edi]
	call	dword [ebx+12]			;CreateSoundBuffer(dsound,&bufdesc,&samples[i],NULL)
	popad
	inc	eax
	add	ebx, byte 4	
	loop	createSampleBuffers
	
;esi = hDC
;ebx = &samples[i]
	xor	eax,eax
	mov	ebx,ABS(dsamples)	
	mov	ecx,NSAMPLES
generateSamples:
	pushad
	mov	edx,[ebx]
	mov	edi,[edx]
	push	dword DSBLOCK_ENTIREBUFFER
	push	byte 0				;ABS(trash)
	push	byte 0
	push	dword ABS(size)
	push	dword ABS(writebuf)
	push	byte 0
	push	byte 0
	push	edx
	call	dword [edi+44]			;Lock(samples[i],0,0,&writebuf,&size,NULL,&trash,DSBLOCK_ENTIREBUFFER);
	popad
	
	
	pushad
	mov	esi,eax
	shl	esi,4

	add	esi,ABS(samples)
	mov	edi,[ABS(writebuf)]
	call	RenderSample
.norender:
	popad
	
	;unga	
	;%include "sgen.inc"
	
	pushad
	mov	edx,[ebx]
	mov	edi,[edx]
	push	byte 0
	push	byte 0
	push	dword [ABS(size)]
	push	dword [ABS(writebuf)]
	push	edx
	call	dword [edi+76]			;Unlock(samples[i],writebuf,size,NULL,0);
	popad
	
	inc	eax
	add	ebx, byte 4
	dec	ecx
	jnz	 generateSamples
		
	
	fld	dword [ABS(cnt33k)]
	mov	edi,ABS(freqtable)
	mov	ecx,8*12
generateFreq:
	;fld	st0
	;fdiv	dword [ABS(cntDiv)]
	fist	dword [edi]
	add	edi, byte 4
	fmul	dword [ABS(cnt105)]
	loop	generateFreq
	fstp	st0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;allocs i precalculs;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;inicialitzar opengl;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;xor	ebx,ebx	
	
;	dword -1,ebx,ebx,ebx,dword FW_BOLD,ebx,ebx,ebx,dword ANSI_CHARSET,
;	dword OUT_TT_PRECIS,dword CLIP_DEFAULT_PRECIS,dword ANTIALIASED_QUALITY,
;	dword FF_ROMAN+VARIABLE_PITCH,dword ABS(TNRString)
	
	push	dword ABS(TNRString)
	push	dword FF_ROMAN+VARIABLE_PITCH
	push	dword ANTIALIASED_QUALITY
	push	dword CLIP_DEFAULT_PRECIS
	push	dword OUT_TT_PRECIS
	push	dword ANSI_CHARSET
	push	byte 0
	push	byte 0
	push	byte 0
	push	dword FW_BOLD
	push	byte 0
	push	byte 0
	push	byte 0
	push	dword -1
	;call	dword [ABS(funcAddress4) + gdiOrdinal.CreateFontA]
	INVOKAH	CreateFontA,gdiOrdinal,funcAddress4
	
	
	;INVOKER ebp+oglImports.CreateFont,dword -1,ebx,ebx,ebx,dword FW_BOLD,ebx,ebx,ebx,dword ANSI_CHARSET,dword OUT_TT_PRECIS,dword CLIP_DEFAULT_PRECIS,dword ANTIALIASED_QUALITY,dword FF_ROMAN+VARIABLE_PITCH,dword ABS(TNRString)
	
	push	eax
	push	esi
	;call	dword [ABS(funcAddress4) + gdiOrdinal.SelectObject]
	INVOKAH	SelectObject,gdiOrdinal,funcAddress4
	;INVOKER ebp+oglImports.SelectObject

		;esi,byte 1,dword 255,byte 1,byte 0,byte 0,dword WGL_FONT_POLYGONS,byte 0

	push	byte 0
	push	WGL_FONT_POLYGONS
	push	byte 0
	push	byte 0
	push	byte 1
	push	dword 255
	push	byte 1
	push	esi
	INVOKAH	wglUseFontOutlinesA,oglOrdinal,funcAddress
	;call	dword [ABS(funcAddress) + oglOrdinal.wglUseFontOutlinesA]

	INVOKAH	gluNewQuadric,gluOrdinal,funcAddress2
	;call	dword [ABS(funcAddress2) + gluOrdinal.gluNewQuadric]
	;INVOKER ebp+oglImports.gluNewQuadric
	mov	[ABS(quadric)],eax
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;end - inicialitzar opengl;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	push	dword ABS(tID)
	push	byte 0
	push	byte 0
	push	dword ABS(threadMain)
	push	byte 0
	push	byte 0
	;INVOKER ebp+oglImports.CreateThread	;,byte 0,byte 0,dword ABS(threadMain),byte 0,byte 0,dword ABS(tID)
	;call	dword [ABS(funcAddress3) + kernelOrdinal.CreateThread]
	INVOKAH	CreateThread,kernelOrdinal,funcAddress3
	mov	[ABS(thH)],eax
	
	push	dword THREAD_PRIORITY_TIME_CRITICAL
	push	eax
	;INVOKER ebp+oglImports.SetThreadPriority	;,eax,dword THREAD_PRIORITY_TIME_CRITICAL
	;call	dword [ABS(funcAddress3) + kernelOrdinal.SetThreadPriority]
	INVOKAH	SetThreadPriority,kernelOrdinal,funcAddress3

	;DO NOT DESTROY esi!!!!!!!!!!!!

	;INVOKER ebp+oglImports.GetTickCount
	;call	dword [ABS(funcAddress3) + kernelOrdinal.GetTickCount]
	INVOKAH	GetTickCount,kernelOrdinal,funcAddress3
	mov	dword [ABS(oldTickCount)],eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   main   ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


_main:	
%ifndef CALL_BY_ORDINAL
	mov	ebp,ABS(oglFunc)
%endif
;********************************************************************************* Update Tick Count
	;call	dword [ABS(funcAddress3) + kernelOrdinal.GetTickCount]
	INVOKAH	GetTickCount,kernelOrdinal,funcAddress3
	sub	eax,[ABS(oldTickCount)]
	push	eax
	fild	dword [esp]
	pop	eax
	fdiv	dword [ABS(timeDivider)]
	fstp	dword [ABS(ts)]	
	
;********************************************************************************* Get win Messages
	xor	ebx,ebx
	;mov	ebp,ABS(Msg)
	
	push	dword PM_REMOVE
	push	ebx
	push	ebx
	push	ebx
	push	ABS(Msg)
	INVOKAH	PeekMessageA,userOrdinal,funcAddress5
	;call	dword [ABS(funcAddress5) + userOrdinal.PeekMessageA]
	;INVOKER	ABS(PeekMessage)
	
	;INVOKER	ABS(PeekMessage),ebp,ebx,ebx,ebx,PM_REMOVE
	mov	eax,[ABS(Msg)+4]
%if	FULLSCREEN==0
	cmp	eax,WM_QUIT
	je	near exitIntro
	cmp	eax,WM_DESTROY
	je	near exitIntro
%endif
	cmp	eax,WM_KEYDOWN
	jne	.normal	
	cmp	dword [ABS(Msg)+8], 0x1B
	je	near exitIntro
.normal
;********************************************************************************* Render new frame
	pushad
	
%ifdef CALL_BY_ORDINAL
	mov	ebp,ABS(funcAddress)							;canviar!
%else
	mov	ebp,ABS(oglFunc)
%endif
	
	
	push	dword GL_LINEAR_MIPMAP_LINEAR
	push	dword GL_TEXTURE_MIN_FILTER
	push	dword GL_TEXTURE_2D
	INVOKAH	glTexParameteri,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTexParameteri]
	
	push	dword GL_TRUE
	push	dword GL_GENERATE_MIPMAP_SGIS
	push	dword GL_TEXTURE_2D
	INVOKAH	glTexParameteri,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTexParameteri]

	;
	;glmatrixmode
	push	dword GL_MODELVIEW
	;gluperspective
	push	dword 0x40540000
	push	byte 0
	push	dword 0x3fb1eb85
	push	dword 0x20000000
	push	dword 0x3ff55555		;0x3ff00000
	push	dword 0x60000000		; byte 0
	push	dword 0x40468000
	push	byte 0
	
	
	;glmatrixmode
	push	dword GL_PROJECTION
	;glclear
	push	dword GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
	;glclearcolor
;	push	byte 0
;	push	dword #0.8#
;	push	byte 0
;	push	byte 0
;	call	dword [ebp + oglOrdinal.glClearColor]
	INVOKAH	glClear,oglOrdinal,ebp
	INVOKAH	glMatrixMode,oglOrdinal,ebp
	INVOKAH	glLoadIdentity,oglOrdinal,ebp
	INVOKAH	gluPerspective,gluOrdinal,funcAddress2
	INVOKAH	glMatrixMode,oglOrdinal,ebp
	INVOKAH	glLoadIdentity,oglOrdinal,ebp
	
;	call	dword [ebp + oglOrdinal.glClear]
;	call	dword [ebp + oglOrdinal.glMatrixMode]
;	call	dword [ebp + oglOrdinal.glLoadIdentity]
;	call	dword [ABS(funcAddress2) + gluOrdinal.gluPerspective]
;	call	dword [ebp + oglOrdinal.glMatrixMode]
;	call	dword [ebp + oglOrdinal.glLoadIdentity]

	mov	eax, [ABS(dacamera)]
	;if (dacamera>=20)
	;	vibra=0.01f*sin((time-800-dacamera*100))/(time-800-dacamera*100);
	cmp	eax,20
	jl	.novibra
	
	push	byte 0
	fld	dword [ABS(ts)]
	fisub	word [ABS(icnt800)]
	fild	dword [ABS(dacamera)]
	fimul	word [ABS(icnt100)]
	fsubp	st1,st0
	fld	st0
	fsin
;	call	myRandFloat
	fdivrp	st1,st0
	fidiv	word [ABS(icnt100)]
	push	eax
	fstp	dword [esp]
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
.novibra:

	mov	eax,[ABS(dacamera)]
	or	eax,eax
	js	.noCameraAtAll
	
	cmp	eax,45
	jge	exitIntro
	
	cmp	eax,36
	jge	.noCameraAtAll
	
	movzx	eax, word [eax * 2 + ABS(camera_table)]
	add	eax,ABS(0)
	jmp	eax
;	jmp	.camera4
	
.camera0:
;camera 0:
;			glTranslatef(0.f,-0.1f,-1.0f);
;			glTranslatef(0,1.f-ts*0.001f+BL_DISP*2,0);
;			glRotatef(90, 1.f, 0.f, 0.f);
			
;	push	dword #-1.0#
;	push	dword #-0.1#
;	push	byte 0
;	call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	dword #-1.0#
	fld	dword [ABS(ts)]
	fmul	dword [ABS(fcnt0d001)]
	fld	dword [ABS(fcnt1d5)]
	fsubrp	st1,st0
;	fadd	dword [ABS(fcnt0d24)]
;	fadd	dword [ABS(fcnt0d24)]
	push	byte 0
	fstp	dword [esp]
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #90.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	jmp	.endCamera

.camera1:
;camera 1:	
;			glTranslatef(0.f,-0.1f*.3f,-3.7f*.3f);
;			glRotatef(50, 1.f, 0.f, 0.f);
;			glRotatef(180.0f+98.0f+ts*0.3f, 0.f, 1.f, 0.f);

	push	dword #-1.11#
	;push	dword #-0.80#
	;push	dword #-0.03#				;casi 0...
	push 	byte 0
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #50.0#
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	
	push	byte 0
	push	dword #1.0#
	push	byte 0

;	AQUEST CALCUL ES PODRIA REAPROFITAR ?	

	fld	dword [ABS(ts)]
	fmul	dword [ABS(fcnt0d3)]
;	fiadd	word [ABS(icnt278)]
	push	byte 0
	fstp	dword [esp]
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	jmp	.endCamera

.camera2:
;camera 2
;			glTranslatef(0.f,.3f,-3.7f*.5f);
;			glRotatef(40, 1.f, 0.f, 0.f);
	push	dword #-1.85#
	push	dword #0.3#
	push	byte 0
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	fld	dword [ABS(ts)]
	fidiv	word [ABS(icnt70)]
	push	byte 0
	fstp	dword [esp]
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #40.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	jmp	.endCamera
	
.camera3:
;camera 3	
;			glTranslatef(0.f,-0.1f*.1f,-3.7f*.1f);
;			glRotatef(30, 1.f, 0.f, 0.f);
;			glRotatef(180.0f+98.0f+ts*0.3f, 0.f, 1.f, 0.f);
	push	dword #-0.37#
;	push	dword #-0.01#			; casi 0
	push 	byte 0
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #30.0#
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	
	fld	dword [ABS(ts)]
	fmul	dword [ABS(fcnt0d3)]
;	fiadd	word [ABS(icnt278)]
	push	byte 0
	fstp	dword [esp]
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	jmp	.endCamera
	
.camera4:
;camera4
;				glRotatef(25, 1.f, 0.f, 0.f);
;				glTranslatef(-BL_DISP*11/2,-0.1f,-caroffsets[0]*BL_DISP*cantonades+carsep*(carnum/2)-BL_DISP*cantonades*dtime0+BL_DISP*6);
;				glRotatef(180,0,1,0);
	push	byte  0
	push	byte  0
	push	dword #1.0#
	push	dword #25.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	
	fld	dword [ABS(caroffsets)+4]
	fadd	dword [ABS(dtime0)]
	fadd	st0,st0
	fmul	dword [ABS(fcnt0d24)]
	
	fsubr	dword [ABS(fcnt1d5)]
	push	byte 0
	fstp	dword [esp]
	
	push	dword #-0.1#
	push	dword #0.84#			;-BL_DISP*11/2
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	
	jmp	.endCamera
.camera5
;camera5
;				glTranslatef(0,-0.2f-FreddyAlt,-FreddyPos-1.2f);
;				glRotatef(25, 1.f, 0.f, 0.f);
;				glRotatef(-90,0,1,0);

	fld	dword [ABS(FreddyPos)]
	fadd	dword [ABS(fcnt1d2)]
	fchs
	push	byte 0
	fstp	dword [esp]
	
	fld	dword [ABS(FreddyAlt)]
	fadd	dword [ABS(fcnt0d2)]
	fchs
	push	byte 0
	fstp	dword [esp]
	push	byte 0
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]
	
	push	byte 0
	push	byte 0
	push	dword #1.0#
	push	dword #25.0#
	INVOKAH	glRotatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glRotatef]
	
	push	byte 0
	push	dword #1.0#
	push	byte 0
	push	dword #-90.0#
	;call	dword [ebp + oglOrdinal.glRotatef]
	INVOKAH	glRotatef,oglOrdinal,ebp
	
.noCameraAtAll
.endCamera

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!QUIETO PARAO
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	;glblendfunc
	push	dword GL_ZERO
	push	dword GL_SRC_ALPHA
	;glenable
	push	dword GL_COLOR_MATERIAL
	push	dword GL_BLEND
	push	dword GL_LIGHT0
	push	dword GL_NORMALIZE
	;glViewport
	push	dword R2T_SIZE
	push	dword R2T_SIZE
	push	byte 0
	push	byte 0
	INVOKAH	glViewport,oglOrdinal,ebp
	INVOKAH	glEnable,oglOrdinal,ebp
	INVOKAH	glEnable,oglOrdinal,ebp
	INVOKAH	glEnable,oglOrdinal,ebp
	INVOKAH	glEnable,oglOrdinal,ebp
	INVOKAH	glBlendFunc,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glViewport]
;	call	dword [ebp + oglOrdinal.glEnable]
;	call	dword [ebp + oglOrdinal.glEnable]
;	call	dword [ebp + oglOrdinal.glEnable]
;	call	dword [ebp + oglOrdinal.glEnable]
;	call	dword [ebp + oglOrdinal.glBlendFunc]
	
	mov	dword [ABS(holdrand)],2
	%include "../build/timeCalc.asm"
	;call	timeCalc

	xor	ebx,ebx

	fld	dword [ABS(ts)]
	push	byte 0
	fist	dword [esp]
	pop	eax

	cmp	eax,800
	jl	.DrawBegin
	inc	ebx
	cmp	eax,4300
	jl	.DrawBegin
	inc	ebx
.DrawBegin
;	mov	[ABS(cv)],ebx				;cv val 1, 0 o 2 segons toca pre,city o post
	fisub	word [ABS(icnt800)]
	fidiv	word [ABS(icnt100)]
	fistp	dword [ABS(dacamera)]		;ale, per a calcular la camera :P
	
;	mov	esi,3
	;	mov	ecx,3
	mov	edi,3
DrawLoop:
	pushad
;	push	esi
	mov	dword [ABS(holdrand)],2
	push	dword ABS(zerov)
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
	cmp	ebx,1
	je	.NoDrawText
	
	;pop	ecx
	;push	ecx
	cmp	edi, 3
	jne	.ColoredFont
	push	dword ABS(fontcolor)
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
.ColoredFont
	;translate

	fild	word [ABS(icnt4750)]
	fld	dword [ABS(ts)]
	fcomi	st0, st1
	fcmovnb	st0, st1		;clamp de la muerte
	
	
	fild	word [ABS(icnt2600)]
	fcomi	st1
	jb	.noHack
	
	fisubr	word [ABS(icnt1150)]
	
.noHack						;fuzzion
	fsubp	st1,st0
	;fisubr	word [ABS(icnt2600)]
	fabs
	fmul	dword [ABS(fcnt0d2)]
	fisub	word [ABS(icnt445)]
	push	byte 0
	fstp	dword [esp]
	push	byte 0
	push	byte 0
		
;	fisub	word [ABS(icnt4700)]
;	fidiv	word [ABS(icnt100)]

;	fld	dword [ABS(ts)]
;	fmul	dword [ABS(fcnt0d2)]
;	fisub	word  [ABS(icnt70)]
;	push	byte 0
;	fstp	dword [esp]
;	fstp	st0
;	push	byte 0
;	push	byte 0

	;gldisenable
	push	dword GL_BLEND
	push	dword GL_LIGHTING
	INVOKAH	glDisable,oglOrdinal,ebp
	INVOKAH	glDisable,oglOrdinal,ebp
	INVOKAH	glLoadIdentity,oglOrdinal,ebp
	INVOKAH	glTranslatef,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glDisable]
;	call	dword [ebp + oglOrdinal.glDisable]
;	call	dword [ebp + oglOrdinal.glLoadIdentity]
;	call	dword [ebp + oglOrdinal.glTranslatef]
	

	fld	dword [ABS(ts)]
	fisub	word [ABS(icnt4700)]
	fidiv	word [ABS(icnt100)]
	push	byte 0
	fistp	dword [esp]
	pop	ebx
	
	cmp	ebx,0
	jge	.nomespetit
	mov	ebx,0
.nomespetit
	cmp	ebx,4
	jle	.nomesgran
	mov	ebx,4
.nomesgran
	
;	cmovb	ebx,eax
	
;	mov	eax,4
;	cmp	ebx,eax
;	cmovnbe	ebx,eax
	
	inc	ebx

	fld	dword [ABS(ts)]
	fidiv	word [ABS(icnt4200)]
	push	byte 0
	fistp	dword [esp]
	pop	esi

;	xor	esi,esi
;	mov	ebx,1
	call	drawText
	jmp	.DrawFinish
.NoDrawText
	;pop	ecx
	;push	ecx
	cmp	edi,1
	je	.DrawFinish
	mov	dword [ABS(holdrand)],14		; 10 queda be
	push	dword GL_DEPTH_TEST
;	push	dword GL_CULL_FACE
	;call	dword [ebp + oglOrdinal.glEnable]
	INVOKAH	glEnable,oglOrdinal,ebp
	push	edi
	;call	drawMultiBlock
	
	%include "../build/drawMultiBlock.asm"
	%include "../build/drawMultiVehicle.asm"
	%include "../build/animatefreddy.inc"
	pop	edi
	push	dword GL_DEPTH_TEST
;	push	dword GL_CULL_FACE
	push	dword GL_BLEND
	push	dword GL_LIGHTING
	;push	dword GL_NORMALIZE
	INVOKAH	glEnable,oglOrdinal,ebp
	INVOKAH	glDisable,oglOrdinal,ebp
	INVOKAH	glDisable,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glEnable]
;	call	dword [ebp + oglOrdinal.glDisable]
;	call	dword [ebp + oglOrdinal.glDisable]
.DrawFinish
	;pop	ecx
	;push	ecx
	cmp	edi,3
	jne	.NoGetR2T
	;glclear
	push	dword GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT			;provar sense el color buffer!!
	;viewport
	push	dword SCREEN_HEIGHT
	push	dword SCREEN_WIDTH
	push	byte  0
	push	byte  0
%if 0	
	;copyteximage
	push	byte  0
	push	dword R2T_SIZE
	push	dword R2T_SIZE
	push	byte  0
	push	byte  0
	push	dword GL_RGBA
	push	byte  0
	push	dword GL_TEXTURE_2D
	INVOKAH	glCopyTexImage2D,oglOrdinal,ebp
%endif
	;TexImage
	push	ABS (da_pixels)
	push	dword GL_UNSIGNED_BYTE
	push	dword GL_RGBA
	push	byte 0
	push	dword R2T_SIZE
	push	dword R2T_SIZE
	push	dword GL_RGBA
	push	byte 0
	push	dword GL_TEXTURE_2D
	;ReadPixels
	push	ABS (da_pixels)
	push	dword GL_UNSIGNED_BYTE
	push	dword GL_RGBA
	push	dword R2T_SIZE
	push	dword R2T_SIZE
	push	byte 0
	push	byte 0
	INVOKAH glReadPixels,oglOrdinal,ebp
	INVOKAH glTexImage2D,oglOrdinal,ebp
	INVOKAH	glViewport,oglOrdinal,ebp
	INVOKAH	glClear,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glCopyTexImage2D]
;	call	dword [ebp + oglOrdinal.glViewport]
;	call	dword [ebp + oglOrdinal.glClear]
	jmp	.NextDrawLoop
.NoGetR2T
	cmp	edi,2
	jne	.NextDrawLoop
	push	dword GL_LIGHTING
	push	dword ABS(onev)
;	call	dword [ebp + oglOrdinal.glColor4ubv]
;	call	dword [ebp + oglOrdinal.glDisable]
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	INVOKAH	glDisable,oglOrdinal,ebp
	call	drawGlow
	
.NextDrawLoop
	;call	dword [ebp + oglOrdinal.glPopMatrix]
	INVOKAH	glPopMatrix,oglOrdinal,ebp
;	pop	esi
	popad
	dec	edi
	jnz	DrawLoop
	push	esi
	;call	dword [ABS(funcAddress) + oglOrdinal.wglSwapBuffers]
	INVOKAH	wglSwapBuffers,oglOrdinal,funcAddress
	jmp	near _main

drawGlow:

	INVOKAH	glLoadIdentity,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glLoadIdentity]
;	glTranslatef(-0.665,-0.5,-1.2);
	push	dword #-1.2#
	push	dword #-0.5#
	push	dword #-0.665#
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]

	push	dword GL_TEXTURE_2D
	INVOKAH	glEnable,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glEnable]
	
	push	dword GL_BLEND
	INVOKAH	glEnable,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glEnable]
	
;	push	dword GL_DEPTH_TEST
;	call	dword [ebp + oglOrdinal.glDisable]
	

	push	dword GL_ONE
	push	dword GL_SRC_ALPHA
	INVOKAH	glBlendFunc,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glBlendFunc]
	
	xor	ecx,ecx
.glowin:
	pushad
%if 0	
	push	dword ecx
	push	dword GL_TEXTURE_BASE_LEVEL
	push	dword GL_TEXTURE_2D
	;call	dword [ebp + oglOrdinal.glTexParameteri]
	INVOKAH	glTexParameteri,oglOrdinal,ebp
%endif
	push	ecx
	inc	dword [esp]
	fild	dword [esp]
	fstp	dword [esp]
	push	dword GL_TEXTURE_LOD_BIAS_EXT
	push	dword GL_TEXTURE_FILTER_CONTROL
	INVOKAH	glTexEnvf,oglOrdinal,ebp
		
	;call	drawQuad
	%include "../build/drawquad.inc"
	
	popad
	inc	ecx
	cmp	ecx,6
	jl	.glowin
%if 0	
	push	byte 0
	push	dword GL_TEXTURE_BASE_LEVEL
	push	dword GL_TEXTURE_2D
	INVOKAH	glTexParameteri,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTexParameteri]
%endif 	
	push	dword GL_TEXTURE_2D
	INVOKAH	glDisable,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glDisable]
	
	push	dword GL_BLEND
	INVOKAH	glDisable,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glDisable]
	
;	call	dword [ebp + oglOrdinal.glPopMatrix]
	ret
%if 0
void drawglow (void)
{
	int cnt;
	glPushMatrix();
	glLoadIdentity();
	glTranslatef(0,0,-1);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);
	glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	for (cnt=0;cnt<6;cnt++)
	{
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL,cnt);
		glBegin(GL_QUADS);
			glTexCoord2d(0,1);	glVertex2d(-1, 1);
			glTexCoord2d(0,0);	glVertex2d(-1,-1);
			glTexCoord2d(1,0);	glVertex2d( 1,-1);
			glTexCoord2d(1,1);	glVertex2d( 1, 1);
		glEnd();
	}
	glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL,0);
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glPopMatrix();
}
%endif

;esi -> da offset
;ebx -> da num
drawText:
	;push	dword GL_COLOR_MATERIAL
	push	dword GL_DEPTH_TEST
	INVOKAH	glDisable,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glDisable]
	
.drawinText:
	;call	dword [ebp + oglOrdinal.glPushMatrix]
	INVOKAH	glPushMatrix,oglOrdinal,ebp
%if 0
	fld     dword [ABS(texsize) + esi * 4]
	fadd    dword [ABS(textvarpos)]
	push    eax
	fstp    dword [esp]
%endif
	push	dword [ABS(texsize) + esi * 4]
	push	dword [ABS(texypos) + esi * 4]
	push	dword [ABS(texxpos) + esi * 4]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glTranslatef]

	movzx	eax,byte [ABS(textoffset) + esi]
	add		eax,ABS(textos)
	push	eax
	push	dword GL_UNSIGNED_BYTE
	
	mov	al,byte [ABS(textoffset) + esi + 1]
	sub	al,byte [ABS(textoffset) + esi    ]
	movzx	eax,al
	push	eax
	INVOKAH	glCallLists,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glCallLists]
	
	INVOKAH	glPopMatrix,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glPopMatrix]
	inc	esi
	dec	ebx
	jnz	.drawinText
	
	ret
%if 0
char *textos="FUZZIONPRESENTSFROGZILLABPUFIXPAINWONDER";
char textoffset[]={0,7,15,24,26,30,34,40};
float texxpos[]={-2.f ,-2.2f,-0.46f,-.47f,-.32f,-.07f,.14f};
float texypos[]={-0.3f,-0.3f,-0.f,-.3f ,-.3f ,-.3f ,-.3f};
float texsize[]={1.f  ,1.f  ,0.18f  ,0.08f,0.08f,0.08f,0.08f};


void drawtext (char daoffset,char danum)
{
	int cnt;
	glDisable(GL_COLOR_MATERIAL);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_CULL_FACE);
	for (cnt=daoffset;cnt<(daoffset+danum);cnt++)
	{
		glPushMatrix();
		glTranslatef(texxpos[cnt],texypos[cnt],-1);
		glCallLists(textoffset[cnt+1]-textoffset[cnt],GL_UNSIGNED_BYTE,textos+textoffset[cnt]);
		glPopMatrix();
	}
}

%endif

;********************************************************************************* Draw Cube

;*************************************************************************************************************************
; DrawCube
;*************************************************************************************************************************
;
;
;  Cridar amb 3 parametres pushats, tamany Z, tamany Y, tamany X
; y,x,z
;  El 2 i el 4 donen problemes amb el GL_CULLFACE.

drawCubeTS:
	INVOKAH	glPushMatrix,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glPushMatrix]
	pop	ebx
	;call	dword [ebp + oglOrdinal.glTranslatef]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	push	ebx			;blehj			canviar aixo, de moment rula pero blehj...
drawCubeScale:
	pop	ebx
	INVOKAH	glScalef,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glScalef]
	push	ebx
drawCube:
	xor	ebx,ebx
	mov	eax,# 1.0#
	mov	edx,#-1.0#
%if 0
	push edx           ;0
	push eax           ;1
	push edx           ;2
	push ebx           ;3
	push ebx           ;4
	push edx           ;5
	push edx           ;6
	push edx           ;7
	push edx           ;8
	push ebx           ;9
	push ebx           ;10
	push edx           ;11
	push eax           ;12
	push eax           ;13
	push edx           ;14
	push eax           ;15
	push ebx           ;16
	push ebx           ;17
	push eax           ;18
	push edx           ;19
	push edx           ;20
	push ebx           ;21
	push edx           ;22
	push ebx           ;23
	push eax           ;24
	push edx           ;25
	push eax           ;26
	push ebx           ;27
	push edx           ;28
	push ebx           ;29
	push edx           ;30
	push edx           ;31
	push edx           ;32
	push edx           ;33
	push ebx           ;34
	push ebx           ;35
	push edx           ;36
	push edx           ;37
	push eax           ;38
	push edx           ;39
	push ebx           ;40
	push ebx           ;41
	push edx           ;42
	push eax           ;43
	push edx           ;44
	push ebx           ;45
	push eax           ;46
	push ebx           ;47
	push edx           ;48
	push eax           ;49
	push eax           ;50
	push ebx           ;51
	push eax           ;52
	push ebx           ;53
	push eax           ;54
	push eax           ;55
	push edx           ;56
	push eax           ;57
	push ebx           ;58
	push ebx           ;59
	push eax           ;60
	push eax           ;61
	push eax           ;62
	push ebx           ;63
	push ebx           ;64
	push eax           ;65
	push eax           ;66
	push edx           ;67
	push eax           ;68
	push ebx           ;69
	push ebx           ;70
	push eax           ;71
	push edx           ;72
	push eax           ;73
	push eax           ;74
	push ebx           ;75
	push ebx           ;76
	push eax           ;77
	push edx           ;78
	push edx           ;79
	push eax           ;80
	push ebx           ;81
	push ebx           ;82
	push eax           ;83
	push dword 5
	;call	dword [ebp + oglOrdinal.glBegin]
	INVOKAH	glBegin,oglOrdinal,ebp
	mov	ebx,14
.drawcube_loop:
	;call	dword [ebp + oglOrdinal.glNormal3f]
	;call	dword [ebp + oglOrdinal.glVertex3f]
	INVOKAH	glNormal3f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	dec	ebx
	jnz	.drawcube_loop
	INVOKAH	glEnd,oglOrdinal,ebp
	;call	dword [ebp + oglOrdinal.glEnd]
%endif

;6
	push	edx        ; -1 
	push	eax        ; 1
	push	eax        ; 1
	
	push	eax        ; 1
	push	eax        ; 1
	push	eax        ; 1
		
	push	eax        ; 1
	push	eax        ; 1
	push	edx        ; -1
	
	push	edx        ; -1
	push	eax        ; 1
	push	edx        ; -1
	
	push	ebx        ; 0
	push	eax        ; 1
	push	ebx        ; 0
	
;5
	push	edx        ; -1
	push	edx        ; -1
	push	eax        ; 1
	
	push	eax        ; 1
	push	edx        ; -1
	push	eax        ; 1
		
	push	eax        ; 1
	push	edx        ; -1
	push	edx        ; -1
	
	push	edx        ; -1
	push	edx        ; -1
	push	edx        ; -1
	
	push	ebx        ; 0
	push	edx        ; -1
	push	ebx        ; 0

;4
	push	eax        ; 1
	push	eax        ; 1
	push	edx        ; -1
	
	push	eax        ; 1
	push	eax        ; 1
	push	eax        ; 1
		
	push	eax        ; 1
	push	edx        ; -1
	push	eax        ; 1
	
	
	push	eax        ; 1
	push	edx        ; -1
	push	edx        ; -1
	
	push	eax        ; 1
	push	ebx        ; 0
	push	ebx        ; 0


;3 	
	push	eax        ; 1
	push	edx        ; -1
	push	edx        ; -1
	
	push	eax        ; 1
	push	eax        ; 1
	push	edx        ; -1
		
	push	edx        ; -1
	push	eax        ; 1
	push	edx        ; -1
	
	
	push	edx        ; -1
	push	edx        ; -1
	push	edx        ; -1
	
	push	ebx        ; 0
	push	ebx        ; 0
	push	edx        ; -1

	
;2 	
	push	eax        ; 1
	push	edx        ; -1
	push	eax        ; 1
	
	push	eax        ; 1
	push	eax        ; 1
	push	eax        ; 1
		
	push	edx        ; -1
	push	eax        ; 1
	push	eax        ; 1
	
	
	push	edx        ; -1
	push	edx        ; -1
	push	eax        ; 1
	
	push	ebx        ; 0
	push	ebx        ; 0
	push	eax        ; 1
	
;1
	
	push	edx        ; -1
	push	eax        ; 1
	push	edx        ; -1
	
	push	edx        ; -1
	push	eax        ; 1
	push	eax        ; 1
		
	push	edx        ; -1
	push	edx        ; -1
	push	eax        ; 1
	
	
	push	edx        ; -1
	push	edx        ; -1
	push	edx        ; -1
	
	push	edx        ; -1
	push	ebx        ; 0
	push	ebx        ; 0
	push	dword	GL_QUADS
	
	;call	dword [ebp + oglOrdinal.glBegin]
	INVOKAH	glBegin,oglOrdinal,ebp
	
	mov	ebx,6
.drawcube_loop:
	;call	dword [ebp + oglOrdinal.glNormal3f]
	;call	dword [ebp + oglOrdinal.glVertex3f]
	;call	dword [ebp + oglOrdinal.glVertex3f]
	;call	dword [ebp + oglOrdinal.glVertex3f]
	;call	dword [ebp + oglOrdinal.glVertex3f]
	INVOKAH	glNormal3f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	INVOKAH	glVertex3f,oglOrdinal,ebp
	dec	ebx
	jnz	.drawcube_loop

	INVOKAH	glEnd,oglOrdinal,ebp
	INVOKAH	glPopMatrix,oglOrdinal,ebp
;	call	dword [ebp + oglOrdinal.glEnd]
;	call	dword [ebp + oglOrdinal.glPopMatrix]
	ret
;*************************************************************************************************************************
; DrawFrog
;*************************************************************************************************************************
	
drawFrog:
	xor	ebx,ebx
	mov	ecx,9
.LoopObjRana

	pushad
	
	;gluSphere
	push	byte 20
	push	byte 20
	fld	dword [ABS(ranarad + ebx)]
	push	eax
	push	eax
	fstp	qword [esp]
	push	dword [ABS(quadric)]		;gluSphere!!!
	
	mov	esi,ebx
	;glColor4uvb
	shr	ebx, 2
	movzx	ebx, byte [ABS(ranarc+ebx)]
	shl	ebx,2
	add	ebx, ABS(Colors)

	push	ebx
	
	; glTranslatef
	push	dword [ABS(ranapz+esi)]
	push	dword [ABS(ranapy+esi)]
	push	dword [ABS(ranapx+esi)]
	
	;call	dword [ebp + oglOrdinal.glTranslatef]
	;call	dword [ebp + oglOrdinal.glColor4ubv]
	INVOKAH	glTranslatef,oglOrdinal,ebp
	INVOKAH	glColor4ubv,oglOrdinal,ebp
	INVOKAH	gluSphere,gluOrdinal,funcAddress2
 	;call	dword [ABS(funcAddress2) + gluOrdinal.gluSphere]
	popad	
	add	ebx, byte 4
	loop	.LoopObjRana
	ret

;*************************************************************************************************************************
; DrawSemaphore
;*************************************************************************************************************************
%if 0
;esi	-> col
drawSemaf:
	inc	esi
	
	mov	eax,ABS(SemafColors)
	add	eax,4*3
	push	eax
	call	dword [ebp + oglOrdinal.glColor4ubv]
	
	push	dword #0.0012#
	push	dword #0.0075#		;0.3 ???
	push	dword #0.0012#
	
	push	byte 0
	push	dword #0.0075#
	push	byte 0
	call	drawCubeTS
	
	push	dword #0.0025#
	push	dword #0.0075#
	push	dword #0.0025#
	
	push	byte 0
	push	dword #0.0225#
	push	byte 0
	call	drawCubeTS
;%if 0	
	xor	ebx,ebx
	mov	[ABS(tmpd)],ebx
	
	mov	ecx,3
.semLoop:
	pushad
	
	mov	eax,ABS(zerov)
	cmp	ecx,esi
	jne	.noCol

	add	eax,ebx
	add	eax,SemafColors - zerov

.noCol:
	;comparar col = ecx...
	push	eax
	call	dword [ebp + oglOrdinal.glColor4ubv]
	
	push	dword #0.001#
	push	dword #0.001#
	push	dword #0.001#
	
	push	byte 0
	
;	fld	dword [ABS(fcnt0d38)]
	fld	dword [ABS(fcnt0d02)]
	fadd	dword [ABS(tmpd)]
	push	eax
	fstp	dword [esp]
	
	push	dword #0.002#
	call	drawCubeTS
	
	fld	dword [ABS(tmpd)]
;	fadd	dword [ABS(fcnt0d07)]
;	fadd	dword [ABS(fcnt0d0035)]
	fadd	dword [ABS(fcnt0d05)]
	fstp	dword [ABS(tmpd)]
	popad
	add	ebx,4
	loop .semLoop
;%endif
	ret
%endif

;********************************************************************************* clampminmaxz1
;st0 = val
clampminmaxz1:
	fldz				;0	value
	fld1				;1	0	value
	fxch	st2			;value	0	1
;********************************************************************************* clampminmax
;st0 = val
;st1 = min
;st2 = max
clampminmax:
	fcomi	st0, st1
	fcmovb	st0, st1
	
	fcomi	st0, st2
	fcmovnb	st0, st2
	
	fxch	st2
	fcompp
	ret
	
%if 0
void timecalc(float time)
{
	float delta;
	float offset;
	int	  toffset;

	FreddyPos=0.0f;
	FreddyAlt=1000.0f;
	if (time>=destructtime){
		delta=(time-destructtime)/100;
		FreddyBPos=(float)floor(delta);
		FreddyBPos+=clampminmax((delta-FreddyBPos)*2.0f,0.0f,1.0f);
		FreddyPos=(FreddyBPos-citylong/2-2)*BL_DISP;
		FreddyAlt=clampminmax(0.4f*(float)sin(delta*(2*PI)),0.0f,1000.0f);
	}

	carrotate=clampminmax((time-frozetime+20.0f)*1.5f,0.0f,30.0f);
	offset=clampminmax(time,0.0f,frozetime);
	dtime0=(float)floor(offset*carvel/cantonades);
	dtime1=offset*carvel/cantonades-dtime0;

	toffset=0;
	for (cepos=0;cepos<carnum;cepos++)
		for (cedge=0;cedge<4;cedge++)
		{
			offset=dtime1-cepos*carfase*carvel/cantonades;
			if ((cedge&1)==1)	offset-=0.5f;
			caroffsets[toffset]=clampminmax(offset/0.4f,0.0f,1.0f);
			semoffsets[toffset]=2;
			if (offset>0.0f)
			{
				if (offset<0.35f) semoffsets[toffset]=0;
				else if (offset<0.5f) semoffsets[toffset]=1;
			}
			toffset++;
		}
}
%endif
	
%if 0	
float clampminmax (float val, float min, float max)
{
	if (val < min) val=min;
	if (val > max) val=max;
	return val;
}
%endif

%if 0
float randomaizer (float p1, float p2, float p3)
{
	return (0.5f+0.49f*(float)sin(14563.0f*p1+23464.0f*p2+94768.0f*p3));
}
%endif

	
;%include "../build/blocks.asm"
;%include "../build/cars.asm"

;********************************************************************************* Exit Intro
exitIntro:
%if FULLSCREEN
	;INVOKER ABS(ChangeDisplaySettings),byte 0,byte 0
	;INVOKER ABS(ShowCursor),byte 1
%endif	
	push	byte 0
	INVOKAH	ExitProcess,kernelOrdinal,funcAddress3
	;call	dword [ABS(funcAddress3) + kernelOrdinal.ExitProcess]
	;INVOKER	ABS(ExitProcess),byte 0
						; no cal pop ni ret, aqui no ha d'arribar mai!


%if 0
	;st0	-> max
frand:
	mov	eax,[ABS(holdrand)]
	imul	eax,214013
	add	eax,2531011
	mov	[ABS(holdrand)],eax
	and	eax,0x7FFF
	
	push	eax
	fild	dword [esp]		;rand()		max
	pop	eax
	
	fidiv	word [ABS(icnt32k)]
	fsub	dword [ABS(cnt05)]
	fmulp	st1,st0
	ret
%endif

%include "inner_pl.inc"
%include "sgen_perxxor.asm"

	vols		dd	-1200,-602,-250,0
	fcarfasevelcant	dd	0.0375
	fcarvelcant	dd	0.0015
%ifdef WIN_XP
	cnt33k		dd	1378.125			;ajustar pq C-5 == freq sample (44100 en aquest cas)
%else
	cnt33k		dd	689.0625 			;ajustar pq C-5 == freq sample (22050 en aquest cas)
%endif

	cnt105		dd	1.05946309436
	fcnt0d001	dd	0.001
	fcnt0d24	dd	0.24
	fcnt0d018	dd	0.018
	fcnt0d3		dd	0.3
	fcnt0d05	dd	0.05
	fcnt1d5		dd	1.5
	fcnt0d4		dd	0.4
	fcnt0d5		dd	0.5
	fcnt1d2		dd	1.2
	fcnt0d2		dd	0.2
	fcnt0d02	dd	0.02
	fcnt0d1		dd	0.1

	icnt3		dw	3
	icnt7		dw	7
	icnt8		dw	8
	icnt11		dw	11
	icnt18		dw	18
	icnt20		dw	20
	icnt30		dw	30
	icnt67		dw	67
	icnt70		dw	70
	icnt800		dw	800
	icnt1000	dw	1000
	icnt1150	dw	1165
	icnt2850	dw	2850
	icnt3150	dw	3100
	icnt4200	dw	4200
	icnt4700	dw	4700
	icnt4750	dw	4750
	icnt2600	dw	2600
	icnt445		dw	445		;una de les 2 anira a parir panteres
	
	tickfactor	dd	8.25		;Relacio entre ts i rows. 12 rows=100(en ts)=2000ms.
;						;Es pot calcular com milisperrow / timedivider

	editName	db 	"EDIT"		;,0			;wow!! 1 byte less!!
	ts		dd	0.0
	timeDivider	dd	20.0

	TNRString	db	"arial",0
	
	textos		db	"FUZZIONFROGZILLABPUFIXPAINWONDER"
	textoffset	db	0,7,16,18,22,26,32
	texxpos		dd	-2.0,-2.6,-6.0,-4.0,-1.0, 2.0
	texypos		dd	-0.3, 0.0,-3.0,-3.0,-3.0,-3.0
	texsize		dd	-1.0, 9.5, 2.0, 2.0, 2.0, 2.0
	
	ranapx		dd	  0.0,-0.189,  0.00, 0.414,  0.0,  0.045,   0.00, 0.081, 0.00
	ranapy		dd	-0.09, -0.18,  0.00,  0.00,  0.00, 0.378,   0.00,  0.00,  0.00
	ranapz		dd	  0.0,  0.18, -0.36,  0.36, -0.36, 0.342, -0.324, 0.306, -0.288
	ranarad		dd	0.315, 0.225, 0.225, 0.1215,0.1215,0.1332, 0.099, 0.063,0.045
	ranarc		db	2,2,2,2,2,1,1,0,0
	
	libNames	dd	ABS(_OpenGL32Name)
			dd	ABS(_glu32Name)
			dd	ABS(_Kernel32Name - _DOSH)
			dd	ABS(_gdi32Name)
			dd	ABS(_User32Name - _DOSH)
			
	libImports	dw	OPENGL_IMPORTS
			dw	GLU_IMPORTS
			dw	KERNEL_IMPORTS
			dw	GDI_IMPORTS
			dw	USER_IMPORTS
	
Colors:					;colors rana
zerov:	db	000, 000, 000, 000
	db	255, 255, 255, 064
	db	000, 200, 000, 128
fanal:	db	204, 204, 204, 000
colorBlock:
	db	051, 051, 064, 000	;dunno
clGlass	db	051, 025, 025, 000

carColors:
	db	170, 000, 000, 064		;vermell amb glow brillant killoak
	db	200, 200, 000, 064		;groc killoak
	db	000, 145, 064, 064		;verd cat-puke
	db	120, 100, 120, 064		;blanc puta
	db	020, 000, 100, 064		;blau carburos metalicos
	db	200, 100, 000, 064		;taronja
	db	080, 100, 150, 064		;gris iluminat
	db	090, 150, 064, 064		;frogzilla
;	db	255, 000, 000, 255
	;db	080, 064, 064, 064		;gris zorra
;carLColors:
;	db	128, 000, 000, 064
;	db	255, 000, 000, 255
	
edifCol	db	080, 080, 080, 000
	db	040, 040, 040, 000
onev:
	db	255, 255, 255, 255
fontcolor:
	db	128, 255, 051, 255
%if 0
SemafColors:
	db	0  ,250,0  , 255
	db	250,150,0  , 255
	db	250,0  ,0  , 255
	db	250,250,0  , 0
%endif

%include "cameratable.inc"
%include "samples.inc"
%include "zik.asm"
%include "imports.inc"

	_IATStuff	times 1024*4 dd		0x80000000
_OffImage:
section .bss
	;_IATStuff	resd	4096	;times	1024*4	dd	0x80000000
	Msg		resd	7
	dsound		resd	1
	dprimary	resd	1
	
	dsamples	resd	20	;NSAMPLES			;6 samples

	oldTickCount	resd	1
	size		resd	1
	writebuf	resd	1
	wTemp		resd	1
	thH		resd	1
	tID		resd	1
	
	freqtable	resd	8*12		
	dmScreen	resd	37
	
	order		resd	1	
	row		resd	1
	
	holdrand	resd	1
	
	quadric		resd	1	
	tmpd		resd	1
	tmpd2		resd	1
	height		resd	1
	destruct	resd	1
	tone		resb	1
	
	dacamera	resd	1
	
	FreddyPos	resd	1
	FreddyBPos	resd	1
	FreddyAlt	resd	1
;	temp		resd	1
	delta		resd	1
	doffset		resd	1
	dtime0		resd	1
	dtime1		resd	1
;	anglea		resd	1
	caroffsets	resd	CAR_NUM * 4
;	semoffsets	resb	CAR_NUM * 4
	carrotate	resd	1
	ncars		resd	1
	cv		resd	1
	funcAddress	resd	OPENGL_IMPORTS + 1	;370
	funcAddress2	resd	GLU_IMPORTS + 1		;53
	funcAddress3	resd	KERNEL_IMPORTS + 1	;943
	funcAddress4	resd	GDI_IMPORTS + 1		;610
	funcAddress5	resd	USER_IMPORTS + 1	;733
	da_pixels	resd	256*256


;perxxor	
	;nsamples	resd	1
;	phase	resd	1
;	buf0	resd	1
;	buf1	resd	1
;	lfc	resd	1
perxxorVars:
	store	resd	1		;4
	f	resd	1		;8
	q	resd	1		;12
	fVal	resd	1		;16
	fdVal	resd	1		;20
	dcut	resd	1		;24
	dres	resd	1		;28
	amp	resd	1		;32
	damp	resd	1		;36
	
_OffModule:
