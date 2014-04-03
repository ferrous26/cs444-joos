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
	shl     eax, 2             ; calculate table offset
	mov     ebx, [ebx]         ; load obj.vtable ptr into ebx
	mov     eax, [ebx + eax]   ; load method pointer into eax
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
	je      .different         ; null is by definition not any type
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
	cmp     eax, 0          ; if (!instanceof) then we need to exit
	je      .bad_cast
	ret                     ; else return true
.ok:
	mov     eax, 1
	ret
.bad_cast:
	mov     eax, class_cast_exception
	call __internal_exception

;; Constants for array ancestor numbers (use these instead of magic numbers)
%define ref#           0x10 ; the first ancestor number for reference types
%define int_array#     0xf
%define short_array#   0xe
%define byte_array#    0xd
%define char_array#    0xc
%define boolean_array# 0xb
%define array#         0x9

;; allocate space for an array, and zero the entire thing
;; the caller of this function will need to initialize the first
;; two fields of the array (vtable, inner vtable), and call
;; the default constructor for each element if the inner type is
;; a reference type
;;
;; pre:  array size in eax, takes over of ebx, edi, esi
;; post: pointer to head of array in eax
global array__allocate
array__allocate:
	cmp     eax, 0         ; array size cannot be <= 0
	jle     .negative_array_size

	mov     ebx, eax       ; backup original size
	add     eax, 3         ; we need to reserve 3 dwords
	shl     eax, 2         ; calculate actual array size
	mov     edi, eax       ; copy size of obj for zeroing
	call __malloc
	mov     esi, eax       ; copy head of array obj
	add     esi, edi       ; move to end of array obj

.zeroing:
	sub     esi, 4         ; move to prev entry
	mov     [esi], dword 0 ; zero out the entry
	cmp     esi, eax       ; are we at head of object
	jne     .zeroing
	mov     [eax + 8], ebx ; copy array length into field spot
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
	mov     eax, [eax + 8] ; offset into object where length is stored
	ret
.null_array:
	mov     eax, null_pointer_exception
	call __internal_exception

;; pre:  index in eax, pointer to array in ebx, take over edi
;; post: value in eax
global array_get
array_get:
	cmp     ebx, 0
	je      .null_array
	cmp     eax, 0
	jl      .out_of_bounds

	mov     edi, [ebx + 8]        ; load length of array
	cmp     eax, edi              ; check out of bounds on right
	jge     .out_of_bounds

	mov     eax, [ebx + 12 + eax] ; load value at index into eax
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
	cmp     ebx, 0          ; check if array ref is null
	je      .null_array
	cmp     eax, 0          ; check if array index is less than zero
	jl      .out_of_bounds
	cmp     ecx, 0          ; if (value == null) skip remaining checks
	je      .post_instanceof

        ; check if the assignment is allowed according to type rules
	; first, we need to save these before calling __instanceof
	push    ecx
	push    ebx
	push    eax

	mov     edi, [ebx + 4]  ; load inner tag pointer

	; if inner tag belongs to a primitive type, we skip __instanceof check
	; because the check will have been statically done during type checking
	cmp     edi, ref#
	jl      .instanceof_epilog

        ; else, we need to get the inner type's ancestor number
	mov     edi, [edi]      ; load atable pointer
	mov     eax, [edi]      ; load atable[0] into expected register
	mov     ebx, ecx        ; place object in expected register
	call __instanceof
	cmp     eax, 0          ; if (instanceof == false)
	je      .array_store_exception

        ; restore stuff we saved before calling __instanceof
.instanceof_epilog:
	pop     eax
	pop     ebx
	pop     ecx

.post_instanceof:
	; now we need to check bounds on the other side
	mov     esi, [ebx + 8]  ; load length
	cmp     eax, esi        ; check out of bounds on right
	jge     .out_of_bounds

	mov     [ebx + 12 + eax], ecx ; load value at index into eax
	mov     eax, ecx              ; fulfill postcondition...?
	ret

.null_array:
	mov     eax, null_pointer_exception
	call __internal_exception

.out_of_bounds:
	mov     eax, array_index_out_of_bounds_exception
	call __internal_exception

.array_store_exception:
	mov     eax, array_store_exception
	call __internal_exception


;; array instanceof check
;;
;; special case of __instanceof for handling array checks
;;
;; pre:  concrete data in ebx, inner type number in eax, takes edi & ebx
;; post: boolean result value will be left in eax
global array_instanceof
array_instanceof:
	cmp     ebx, 0             ; if (ebx == null) return false
	je     .different          ; null is by definition not any type

        ; load the type number of the concrete object
	mov     edi, [ebx]         ; load obj.vtable ptr into edi
	mov     edi, [edi]         ; load obj.atable ptr into edi
	mov     edi, [edi]         ; load obj.atable[0] into edi

	; check if the concrete type is an array
	cmp     edi, array#
	jne     .different

        ; check if the inner type of the array is a primitive
	mov     edi, [ebx + 4]     ; load the inner vtable ptr
	cmp     edi, ref#
	jge     .recursive_case    ; fuuuuu

	; since it is a primitive type, we must check against given type
	cmp     edi, eax
	jne     .different
	; else, inner type is a match, so instanceof returns true
	mov     eax, 1
	ret

.recursive_case:
	add     ebx, 4             ; chop off the head of the arry ptr
	call __instanceof
	ret

.different:
	mov     eax, 0
	ret

;; array downcast check
;;
;; special case of downcasting check for handling array casting
;;
;; pre:  concrete data in ebx, inner type number in eax, takes over ebx & edi
;; post: boolean result value will be left in eax
global array_downcast_check
array_downcast_check:
	cmp     ebx, 0          ; if (ebx == null) return true
	je      .ok             ; null cast is always a success
	call array_instanceof
	; if instanceof is false, it is an illegal cast and we need to exit
	cmp     eax, 0          ; if (!instanceof)
	je      .bad_cast
	ret                     ; else return true
.ok:
	mov     eax, 1
	ret
.bad_cast:
	mov     eax, class_cast_exception
	call __internal_exception

;; print out an exception message and then exit
;;
;; pre:  pointer to exception string in eax
;; post: N/A
__internal_exception:
	call __debug_print
	call __exception

global __null_pointer_exception
__null_pointer_exception:
	mov     eax, null_pointer_exception
	call __debug_print
	call __exception


section .data

debug_message:                         db 'oops                           ', 10
dispatch_exception:                    db 'dispatch problem               ', 10
null_pointer_exception:                db 'NullPointerException           ', 10
arithmetic_exception:                  db 'ArithmeticException            ', 10
class_cast_exception:                  db 'ClassCastException             ', 10
array_store_exception:                 db 'ArrayStoreException            ', 10
negative_array_size_exception:         db 'NegativeArraySizeException     ', 10
array_index_out_of_bounds_exception:   db 'ArrayIndexOutOfBoundsException ', 10
