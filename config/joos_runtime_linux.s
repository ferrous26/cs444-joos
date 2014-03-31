global __debug_print
__debug_print:
	mov     ecx, eax  ; address of bytes to write
	mov     eax, 4    ; sys_write system call
	mov     ebx, 1    ; stdout
	mov     edx, 32   ; number of bytes to write
	int     0x80
	mov     eax, 0     ; return 0
	ret
