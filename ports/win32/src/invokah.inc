%ifdef CALL_BY_ORDINAL
	%macro INVOKAH 3
		%ifidni %3,ebp
		call dword [ebp + %2.%1]
		%else
		call dword [ABS(%3) + %2.%1]	
		%endif
	%endmacro
%else
	%macro INVOKAH 3
		;call dword [ABS(oglFunc) + oglImports.%1]		
		INVOKER ABS(%1)
	%endmacro
%endif