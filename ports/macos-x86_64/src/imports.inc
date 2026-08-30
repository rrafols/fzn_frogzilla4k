; ---------------------------------------------------------------------------
;  Replacement for the Win32 IMPORTS.INC and the five *Ordinal.inc tables.
;
;  Order is deliberate: the first 32 entries are the ones called from inner
;  loops, and RBX points at imports+128 so those reach through a 3-byte
;  "call [rbx+disp8]" instead of the 6-byte disp32 form.
; ---------------------------------------------------------------------------

%macro IMPORT_LIST 0
    ; --- hot path (kept inside the signed-byte displacement window) --------
    IMP glVertex3f
    IMP glNormal3f
    IMP glTranslatef
    IMP glColor4ubv
    IMP glPushMatrix
    IMP glPopMatrix
    IMP glRotatef
    IMP glScalef
    IMP glBegin
    IMP glEnd
    IMP glEnable
    IMP glDisable
    IMP gluSphere
    IMP glCallLists
    IMP glMatrixMode
    IMP glLoadIdentity
    IMP glClear
    IMP glViewport
    IMP glBlendFunc
    IMP glTexParameteri
    IMP glTexEnvf
    IMP glTexCoord2f
    IMP glReadPixels
    IMP glTexImage2D
    IMP gluPerspective
    IMP CGLFlushDrawable
    IMP CGEventSourceKeyState
    IMP clock_gettime_nsec_np
    IMP glBindTexture
    IMP glColor3f
    IMP glCopyTexImage2D
    IMP glGetIntegerv
    ; --- start-up / shutdown only ------------------------------------------
    IMP CGMainDisplayID
    IMP CGDisplayCapture
    IMP CGDisplayIDToOpenGLDisplayMask
    IMP CGDisplayRelease
    IMP CGLChoosePixelFormat
    IMP CGLCreateContext
    IMP CGLSetCurrentContext
    IMP CGLSetFullScreenOnDisplay
    IMP CGLSetParameter
    IMP AudioQueueNewOutput
    IMP AudioQueueAllocateBuffer
    IMP AudioQueueEnqueueBuffer
    IMP AudioQueueStart
    IMP glGenTextures
    IMP gluNewQuadric
    IMP glNewList
    IMP glEndList
    IMP exit
    ; --- the text: glyph outlines from CoreText, filled by the GLU tessellator
    IMP CFStringCreateWithCString
    IMP CTFontCreateWithName
    IMP CTFontGetGlyphsForCharacters
    IMP CTFontCreatePathForGlyph
    IMP CTFontGetAdvancesForGlyphs
    IMP CGPathApply
    IMP gluNewTess
    IMP gluTessCallback
    IMP gluTessProperty
    IMP gluTessNormal
    IMP gluTessBeginPolygon
    IMP gluTessBeginContour
    IMP gluTessVertex
    IMP gluTessEndContour
    IMP gluTessEndPolygon
    IMP glVertex3dv
%if WINDOWED
    ; --- only linked into the windowed build --------------------------------
    IMP objc_getClass
    IMP sel_registerName
    IMP objc_msgSend
    IMP NSDefaultRunLoopMode
%endif
%if OFFSCREEN
    ; --- only linked into the offscreen frame-dump build -------------------
    IMP glGenFramebuffersEXT
    IMP glBindFramebufferEXT
    IMP glGenRenderbuffersEXT
    IMP glBindRenderbufferEXT
    IMP glRenderbufferStorageEXT
    IMP glFramebufferRenderbufferEXT
    IMP fopen
    IMP fwrite
    IMP fclose
%endif
%endmacro
