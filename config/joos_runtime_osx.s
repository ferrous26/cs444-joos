; Debug output
global __debug_print
__debug_print:
	push    dword 32     ; push strlen
	push    dword eax    ; push char* onto stack
	push    dword 1      ; push file descriptor onto stack
	mov     eax, 4       ; setup system call
	sub     esp, 4       ; align stack address
	int     0x80         ; go go system call
	add     esp, 16      ; pop the stack frame
	mov     eax, 0       ; return 0
	ret
