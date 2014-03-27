;; The Joos Runtime

extern __malloc
extern __debexit
extern __exception
extern __NATIVEjava.io.OutputStream.nativeWrite

;; division
;; pre:  dividend in eax, divisor in ebx, we take over edx, and
;;       eax must be a full int
;; post: quotient in eax, remainder in edx
global __division
__division:
	cmp    ebx, 0           ; trying to divide is not allowed!
	je     divide_by_zero
	cdq                     ; sign extend eax into edx
	idiv   ebx
	ret
divide_by_zero:
	__exception

;; kind_of_type
;; pre:  left type in eax, right type in ebx
;; post: boolean value will be left in eax
;;
;; This is essentially the assignability check, but only for reference types
;; left := right ? is right type a kind of left type?
global __kind_of_type
__kind_of_type:
	mov    eax, 0 ; false, because this needs to be implemented
	;; TODO: IMPLEMENT ME!

;; instanceof check
;;
;; paraphrasing: is the given type an ancestor of the type of the concrete data
;;
;; pre:  concrete data in ebx, type pointer in eax
;; post: boolean value will be left in eax
global __instanceof
__instanceof:
	cmp    eax, 0          ; perform null check
	je     instanceof_null
	mov    ebx, [ebx]      ; get the tag for the object
	call __kind_of_type    ; delegate actual check
	ret
instanceof_null:
	mov    eax, 0          ; false
	ret


;; downcast check
;;
;; paraphrasing: is the given type an ancestor of the type of the concrete data
;;
;; pre:  concrete data in ebx, type pointer in eax
;; post: boolean value will be left in eax
global __downcast_check
__downcast_check:
	call __instanceof
	cmp    eax, 0          ; if not instanceof, then we have a problem
	je     bad_cast
	mov    eax, 1          ; true
	ret
instanceof_null:
	call __exception       ; bad cast exception


;; TODO:
;; instance method dispatch
;; array inner type
;; array length
;; array element access
;; array element assignment
;; array allocation
;;  -> zero out the data before running init/constructors
;; execute field initializer
;; assign static field
