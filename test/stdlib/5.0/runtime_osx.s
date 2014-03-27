section .text

; Allocates eax bytes of memory. Pointer to allocated memory returned in eax.
    global __malloc
__malloc:
    push eax
    mov eax, 45  ; sys_brk system call
    mov ebx, 0   ; 0 bytes - query current brk
    int 0x80
    pop ebx
    push eax
    add ebx, eax ; move brk ahead by number of bytes requested
    mov eax, 45  ; sys_brk system call
    int 0x80
    pop ebx
    cmp eax, 0   ; on error, exit with code 22
    jne ok
    mov eax, 22
    call __debexit
ok:
    mov eax, ebx
    ret

; Debugging exit: ends the process, returning the value of
; eax as the exit code.
    global __debexit
__debexit:
    push dword eax ; set exit code to eax
    push dword 0   ; add some pointless padding that is required
    mov  eax,  1   ; sys_exit system call
    int  0x80

; Exceptional exit: ends the process with exit code 13.
; Call this in cases where the Joos code would throw an exception.
    global __exception
__exception:
    push dword 13  ; set exit code to 13
    push dword 0   ; padding
    mov  eax,  1   ; sys_exit system call
    int  0x80

; Implementation of java.io.OutputStream.nativeWrite method.
; Outputs the low-order byte of eax to standard output.
    global NATIVEjava.io.OutputStream.nativeWrite
NATIVEjava.io.OutputStream.nativeWrite:
    mov     [char], al   ; actually load char the char*
    push    dword 1      ; push strlen (we always print 1 byte)
    push    dword char   ; push char* onto stack
    push    dword 1      ; push file descriptor onto stack
    mov     eax, 4       ; setup system call
    sub     esp, 4       ; align stack address
    int     0x80         ; go go system call
    add     esp, 16      ; pop the stack frame
    mov     eax, 0       ; return 0
    ret

section .data

char: dd 0
