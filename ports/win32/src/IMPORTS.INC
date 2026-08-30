%ifdef CALL_BY_ORDINAL
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------

align 4, db 0
IMPORT_DLL _Kernel32Name-_DOSH, _Kernel32Pointers, _Kernel32Pointers
IMPORT_DLL _DSoundName, _dsoundPointers, _dsoundPointers
END_IMPORT_DLL

_Kernel32Pointers:
oglFunc:
GetProcAddress		dd _GetProcAddress-_DOSH
LoadLibrary		dd _LoadLibrary-_DOSH
			dd 0

_dsoundPointers:
DirectSoundCreate	dd _DirectSoundCreate
			dd 0
			dd 0
	
	IMPORT_FUNCTION _DirectSoundCreate,	'DirectSoundCreate'
	db	0
		
	struc	oglImports
		.GetProcAddress		resd 	1
		.LoadLibrary		resd 	1
		.reserved1		resd	1
		.DirectSoundCreate	resd	1
	endstruc
%else

;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
;-- Imports -----------------------------------------------------------------
align 4, db 0
IMPORT_DLL _User32Name-_DOSH, _User32Pointers, _User32Pointers
IMPORT_DLL _Kernel32Name-_DOSH, _Kernel32Pointers, _Kernel32Pointers
IMPORT_DLL _OpenGL32Name, _OpenGL32Pointers, _OpenGL32Pointers
IMPORT_DLL _glu32Name, _glu32Pointers, _glu32Pointers
IMPORT_DLL _DSoundName, _dsoundPointers, _dsoundPointers
IMPORT_DLL _gdi32Name, _gdi32Pointers, _gdi32Pointers
END_IMPORT_DLL

_Kernel32Pointers:
oglFunc:
ExitProcess		dd _ExitProcess
CreateThread		dd _CreateThread
SetThreadPriority	dd _SetThreadPriority
WaitForSingleObject	dd _WaitForSingleObject
GetTickCount		dd _GetTickCount
			dd 0
_User32Pointers:
CreateWindowExA		dd _CreateWindowExA
PeekMessageA		dd _PeekMessageA
DefWindowProc		dd _DefWindowProc
GetDC			dd _GetDC
ChangeDisplaySettingsA	dd _ChangeDisplaySettingsA
ShowCursor		dd _ShowCursor
			dd 0
			
_OpenGL32Pointers:
wglMakeCurrent		dd _wglMakeCurrent
wglCreateContext	dd _wglCreateContext
wglSwapBuffers		dd _wglSwapBuffers
wglUseFontOutlinesA	dd _wglUseFontOutlinesA

glClear			dd _glClear
glClearColor		dd _glClearColor
glEnable		dd _glEnable
glDisable		dd _glDisable
glBlendFunc		dd _glBlendFunc
glMatrixMode		dd _glMatrixMode
glLoadIdentity		dd _glLoadIdentity
glTexImage2D		dd _glTexImage2D
glTexParameteri		dd _glTexParameteri
glBegin			dd _glBegin
glEnd			dd _glEnd
glNewList		dd _glNewList
glEndList		dd _glEndList
glCallLists		dd _glCallLists
glTexCoord2f		dd _glTexCoord2f
glVertex3f		dd _glVertex3f
glNormal3f		dd _glNormal3f
glPolygonMode		dd _glPolygonMode
glColor4ubv		dd _glColor4ubv
glTranslatef		dd _glTranslatef
glRotatef		dd _glRotatef
glCopyTexImage2D	dd _glCopyTexImage2D
glScalef		dd _glScalef
glPointSize		dd _glPointSize
glPushMatrix		dd _glPushMatrix
glPopMatrix		dd _glPopMatrix
glViewport		dd _glViewport
glReadPixels		dd _glReadPixels
glTexEnvf		dd _glTexEnvf
			dd  0
			
_glu32Pointers:
gluPerspective		dd _gluPerspective
gluNewQuadric		dd _gluNewQuadric
gluSphere		dd _gluSphere
			dd 0	

_dsoundPointers:
DirectSoundCreate	dd _DirectSoundCreate
			dd 0

_gdi32Pointers:
ChoosePixelFormat	dd _ChoosePixelFormat
SetPixelFormat		dd _SetPixelFormat
CreateFontA		dd _CreateFontA
SelectObject		dd _SelectObject
			dd 0

			dd 0

	IMPORT_FUNCTION	_ExitProcess,		'ExitProcess'
	IMPORT_FUNCTION	_CreateThread,		'CreateThread'
	IMPORT_FUNCTION	_SetThreadPriority,	'SetThreadPriority'
	IMPORT_FUNCTION _WaitForSingleObject,	'WaitForSingleObject'
	IMPORT_FUNCTION _GetTickCount,		'GetTickCount'
		
	IMPORT_FUNCTION _CreateWindowExA,	'CreateWindowExA'
	IMPORT_FUNCTION	_PeekMessageA,		'PeekMessageA'
	IMPORT_FUNCTION	_DefWindowProc,		'DefWindowProcA'
	IMPORT_FUNCTION	_GetDC,			'GetDC'
	IMPORT_FUNCTION _ChangeDisplaySettingsA, 'ChangeDisplaySettingsA'	
	IMPORT_FUNCTION _ShowCursor,		'ShowCursor'
	
	IMPORT_FUNCTION _wglMakeCurrent,	'wglMakeCurrent'
	IMPORT_FUNCTION	_wglCreateContext,	'wglCreateContext'
	IMPORT_FUNCTION	_wglSwapBuffers,	'wglSwapBuffers'
	IMPORT_FUNCTION _wglUseFontOutlinesA,	'wglUseFontOutlinesA'

	IMPORT_FUNCTION _glClear,		'glClear'
	IMPORT_FUNCTION _glClearColor,		'glClearColor'
	IMPORT_FUNCTION _glEnable,		'glEnable'
	IMPORT_FUNCTION _glDisable,		'glDisable'
	IMPORT_FUNCTION _glBlendFunc,		'glBlendFunc'
	IMPORT_FUNCTION _glMatrixMode,		'glMatrixMode'
	IMPORT_FUNCTION _glLoadIdentity,	'glLoadIdentity'
	IMPORT_FUNCTION _glTexImage2D,		'glTexImage2D'	
	IMPORT_FUNCTION _glTexParameteri,	'glTexParameteri'
	IMPORT_FUNCTION _glBegin,		'glBegin'
	IMPORT_FUNCTION	_glEnd,			'glEnd'	
	IMPORT_FUNCTION _glNewList,		'glNewList'
	IMPORT_FUNCTION _glEndList,		'glEndList'
	IMPORT_FUNCTION _glCallLists,		'glCallLists'
	IMPORT_FUNCTION _glTexCoord2f,		'glTexCoord2f'
	IMPORT_FUNCTION _glVertex3f,		'glVertex3f'
	IMPORT_FUNCTION _glNormal3f,		'glNormal3f'
	IMPORT_FUNCTION _glPolygonMode,		'glPolygonMode'
	IMPORT_FUNCTION _glColor4ubv,		'glColor4ubv'
	IMPORT_FUNCTION _glTranslatef,		'glTranslatef'
	IMPORT_FUNCTION _glRotatef,		'glRotatef'
	IMPORT_FUNCTION _glCopyTexImage2D,	'glCopyTexImage2D'
	IMPORT_FUNCTION _glScalef,		'glScalef'
	IMPORT_FUNCTION _glPointSize,		'glPointSize'
	IMPORT_FUNCTION _glPushMatrix,		'glPushMatrix'
	IMPORT_FUNCTION _glPopMatrix,		'glPopMatrix'
	IMPORT_FUNCTION _glViewport,		'glViewport'
	IMPORT_FUNCTION	_glReadPixels,		'glReadPixels'
	IMPORT_FUNCTION	_glTexEnvf,		'glTexEnvf'
	
	IMPORT_FUNCTION _gluPerspective,	'gluPerspective'
	IMPORT_FUNCTION _gluNewQuadric,		'gluNewQuadric'
	IMPORT_FUNCTION _gluSphere,		'gluSphere'
	
	IMPORT_FUNCTION _DirectSoundCreate,	'DirectSoundCreate'	
	
	IMPORT_FUNCTION _ChoosePixelFormat,	'ChoosePixelFormat'
	IMPORT_FUNCTION _SetPixelFormat,	'SetPixelFormat'
	IMPORT_FUNCTION _CreateFontA,		'CreateFontA'
	IMPORT_FUNCTION _SelectObject,		'SelectObject'
	db	0	
	
	struc	oglImports
		.ExitProcess		resd	1
		.CreateThread		resd	1
		.SetThreadPriority	resd	1
		.WaitForSingleObject	resd	1
		.GetTickCount		resd	1
		.reserved0001		resd	1
		.CreateWindowExA	resd	1
		.PeekMessageA		resd	1
		.DefWindowProc		resd	1
		.GetDC			resd	1
		.ChangeDisplaySettingsA	resd	1
		.ShowCursor		resd	1
		.reserved0002		resd	1
		.wglMakeCurrent		resd	1
		.wglCreateContext	resd	1
		.wglSwapBuffers		resd	1
		.wglUseFontOutlinesA	resd	1
		.glClear		resd	1
		.glClearColor		resd	1
		.glEnable		resd	1
		.glDisable		resd	1
		.glBlendFunc		resd	1
		.glMatrixMode		resd	1
		.glLoadIdentity		resd	1
		.glTexImage2D		resd	1
		.glTexParameteri	resd	1
		.glBegin		resd	1
		.glEnd			resd	1
		.glNewList		resd	1
		.glEndList		resd	1
		.glCallLists		resd	1
		.glTexCoord2f		resd	1
		.glVertex3f		resd	1
		.glNormal3f		resd	1
		.glPolygonMode		resd	1
		.glColor4ubv		resd	1
		.glTranslatef		resd	1
		.glRotatef		resd	1
		.glCopyTexImage2D	resd	1
		.glScalef		resd	1
		.glPointSize		resd	1
		.glPushMatrix		resd	1
		.glPopMatrix		resd	1
		.glViewport		resd	1
		.glReadPixels		resd	1
		.glTexEnvf		resd	1
		.reserved1		resd	1
		.gluPerspective		resd	1
		.gluNewQuadric		resd	1
		.gluSphere		resd	1
		.reserved0003		resd	1
		.DirectSoundCreate	resd	1
		.reserved0004		resd	1
		.ChoosePixelFormat	resd	1
		.SetPixelFormat		resd	1
		.CreateFontA		resd	1
		.SelectObject		resd	1
	endstruc
%endif