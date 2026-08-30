; The camera arrangement itself lives in ..\..\..\common\data\cameras.inc and
; is shared with the other ports.  Here each entry becomes a jump-table slot,
; which is what the original file held literally.

%macro CAM 1
	dw	_main.camera %+ %1
%endmacro

camera_table:
%include "cameras.inc"
