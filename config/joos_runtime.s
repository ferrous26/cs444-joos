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
	cmp     ebx, 0             ; first, check if receiver is null
	je      .null_pointer
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
.null_pointer:
	mov     eax, null_pointer_exception
	call __internal_exception

;; division/modulo
;; pre:  dividend in eax, divisor in ebx, we take ownership of edx, and
;;       eax must be already be a full int (sign extended)
;; post: quotient in eax, remainder in edx
global __division
global __modulo
__division:
__modulo:
	cmp     ebx, 0           ; trying to divide by 0 is not allowed!
	je      .divide_by_zero
	cdq                      ; sign extend eax into edx
	idiv    ebx
	ret
.divide_by_zero:
	mov     eax, arithmetic_exception
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
	mov     eax, class_cast_exception
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

;; allocate space for an array, and zero the entire thing
;; the caller of this function will need to initialize the first
;; two fields of the array (vtable, ancestor number), and call
;; the default constructor for each element if the inner type is
;; a reference type
;;
;; pre:  array size in eax, takes over of ebx, edi, esi
;; post: pointer to head of array in eax
global array__allocate
array__allocate:
	cmp     eax, 0         ; array size cannot be <= 0
	jle     .negative_array_size
	mov     ebx, eax
	mov     edi, eax       ; copy array size as counter
	add     edx, 3         ; we need to reserve 3 dwords
	imul    edi, 4         ; calculate actual array size
	mov     eax, edi
	call __malloc
	mov     esi, eax       ; copy head of array
	add     esi, edi       ; move to end of array
.zeroing:
	sub     esi, 4         ; move to prev entry
	mov     [esi], dword 0 ; zero out the entry
	cmp     esi, eax       ; are we at head of object
	jne     .zeroing
	add     esi, 8         ; copy array length into field spot
	mov     [esi], ebx
	ret
.negative_array_size:
	mov     eax, negative_array_size_exception
	call __internal_exception

;; Access the length of the array
;;
;; pre:  pointer to array is in eax
;; post: length of array is in eax
global array?length
array?length:
	cmp     eax, 0
	je      .null_array
	add     eax, 8
	mov     eax, [eax]
	ret
.null_array:
	mov     eax, null_pointer_exception
	call __internal_exception

;; pre:  index in eax, pointer to array in ebx, take over edi & esi
;; post: value in eax
global array_get
array_get:
	cmp     ebx, 0
	je      .null_array
	cmp     eax, 0
	jl      .out_of_bounds
	mov     edi, ebx        ; copy pointer to temp
	add     edi, 8          ; move pointer to length
	mov     esi, [edi]      ; load length
	cmp     eax, esi        ; check out of bounds on right
	jge     .out_of_bounds
	add     edi, 4          ; move tmp pointer to array data
	add     edi, eax        ; move to correct index
	mov     eax, [edi]      ; load value at index into eax
	ret
.null_array:
	mov     eax, null_pointer_exception
	call __internal_exception
.out_of_bounds:
	mov     eax, array_index_out_of_bounds_exception
	call __internal_exception

;; pre:  index in eax, pointer to array in ebx, value in ecx
;; post: value in eax?
global array_set
array_set:
	; check if array ref is null, and if index is less than zero
	cmp     ebx, 0
	je      .null_array
	cmp     eax, 0
	jl      .out_of_bounds
	mov     edi, ebx        ; copy pointer to temp

        ; check if the assignment is allowed according to type rules
	; first, we need to save these before calling __instanceof
	push    edi
	push    ebx
	push    eax
	add     esp, 4          ; align the stack

	add     edi, 4          ; move pointer to inner type
	mov     eax, [edi]      ; load ancestor number of inner type
	cmp     eax, 0x10       ; skip check for instanceof primitive
	jl      .post_instanceof
	call __instanceof
	cmp     eax, 0
	je      .set_exception

        ; restore stuff we saved before calling __instanceof
.post_instanceof:
	sub     esp, 4          ; pop stack
	pop     edi
	pop     ebx
	pop     eax

	; now we need to check bounds on the other side
	add     edi, 8          ; move pointer to length
	mov     esi, [edi]      ; load length
	cmp     eax, esi        ; check out of bounds on right
	jge     .out_of_bounds

	add     edi, 4          ; move tmp pointer to array data
	add     edi, eax        ; move to correct index
	mov     [edi], ecx      ; load value at index into eax
	mov     eax, ecx        ; fulfill postcondition...?
	ret
.null_array:
	mov     eax, null_pointer_exception
	call __internal_exception
.out_of_bounds:
	mov     eax, array_index_out_of_bounds_exception
	call __internal_exception
.set_exception:
	mov     eax, array_store_exception
	call __internal_exception

;; TODO:
;; array instanceof check


;; print out an exception message and then exit
;;
;; pre:  pointer to exception string in eax
;; post: N/A
__internal_exception:
	call __debug_print
	call __exception

section .data

dispatch_exception:                    db 'dispatch problem               ', 10
null_pointer_exception:                db 'NullPointerException           ', 10
arithmetic_exception:                  db 'ArithmeticException            ', 10
class_cast_exception:                  db 'ClassCastException             ', 10
array_store_exception:                 db 'ArrayStoreException            ', 10
negative_array_size_exception:         db 'NegativeArraySizeException     ', 10
array_index_out_of_bounds_exception:   db 'ArrayIndexOutOfBoundsException ', 10
