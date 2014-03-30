;; The Joos Runtime

extern __malloc
extern __debexit
extern __exception
extern __debug_print

;; method dispatch (actually, just finding the correct method pointer)
;;
;; pre:  object in ebx, method number in eax
;; post: method pointer in eax
global __dispatch
__dispatch:
	imul    eax, 4             ; calculate table offset
	mov     ebx, [ebx]         ; load obj.vtable ptr into ebx
	add     ebx, eax           ; add table offset
	mov     eax, [ebx]         ; load method pointer into eax
	cmp     eax, 0             ; debug check if (method_ptr == null)
	je      .bad_method
	ret
.bad_method:
	mov     eax, dispatch_exception
	call __internal_exception

;; division
;; pre:  dividend in eax, divisor in ebx, we take ownership of edx, and
;;       eax must be already be a full int (sign extended)
;; post: quotient in eax, remainder in edx
global __division
__division:
	cmp     ebx, 0           ; trying to divide is not allowed!
	je      .divide_by_zero
	cdq                      ; sign extend eax into edx
	idiv    ebx
	ret
.divide_by_zero:
	mov     eax, division_exception
	call    __internal_exception

;; instanceof check
;;
;; paraphrasing: is the given type an ancestor of the type of the concrete data
;;
;; pre:  concrete data in ebx, type number in eax, takes ownership of ebx & edi
;; post: boolean result value will be left in eax
global __instanceof
__instanceof:
	cmp     ebx, 0             ; if (ebx == null) return false
	jne     .prolog            ; else begin table lookup
	mov     eax, 0
	ret
.prolog:
	mov     ebx, [ebx]         ; load obj.vtable ptr into ebx
	mov     ebx, [ebx]         ; load obj.atable ptr into ebx
	mov     edi, [ebx]         ; load obj.atable[0] into edi
	cmp     eax, edi
	je      .same
.loop:
	add     ebx, 4             ; move obj.atable ptr to next index
	mov     edi, [ebx]
	cmp     edi, 0             ; check if we hit end of obj.atable
	je      .different
	cmp     eax, edi
	jne     .loop              ; try next obj.atable entry
.same:
	mov     eax, 1
	ret
.different:
	mov     eax, 0
	ret

;; downcast check
;;
;; paraphrasing: is the cast type an ancestor of the type of the concrete data
;;
;; pre:  concrete data in ebx, type number in eax, takes ownership of ebx & edi
;; post: boolean result value will be left in eax
global __downcast_check
__downcast_check:
	cmp     ebx, 0          ; if (ebx == null) return true
	je      .ok             ; null cast is always a success
	call __instanceof
	cmp     eax, 1          ; else return (ebx instanceof eax)
	jne     .bad_cast
.ok:
	mov     eax, 1
	ret
.bad_cast:
	mov     eax, bad_cast_exception
	call __internal_exception

;; object allocation
;;
;; pre:  size in eax, vtable ptr in ebx
;; post: pointer to new object in eax
global __allocate
__allocate:
	call __malloc
	mov     [eax], ebx    ; put vtable pointer in place
	; do I need to zero out the object?
	; call constructor
	ret

;; pre: array size in eax, vtable ptr in ebx
;; post: pointer to head of array in eax
global __allocate_array
__allocate_array:
	; check if array size is greater than 0
	mov     edi, eax      ; copy array size as counter
	imul    eax, 4        ; calculate actual array size
	call __malloc
	; if constructor is primitive
        ;   zero the array
	; else
	;   allocate object for each array element and insert it

;; TODO:
;; array length
;; array element access
;; array element assignment
;; array instanceof check


;; print out an exception message and then exit
;;
;; pre:  pointer to exception string in eax
;; post: N/A
__internal_exception:
	call __debug_print
	call __exception

section .data

division_exception: db 'divide by zero                 ', 10
bad_cast_exception: db 'bad cast                       ', 10
dispatch_exception: db 'dispatch problem               ', 10
