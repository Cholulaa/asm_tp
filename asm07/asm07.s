section .data
buf:    times 32 db 0

section .text
global _start

; -----------------------------------------------------------
; Reads up to 32 bytes from stdin => buf
; parse => RAX = integer (>=0) or RAX = -1 on invalid input
; if RAX = -1 => exit(2)
; else if RAX < 2 => exit(1)
; else prime => exit(0), not prime => exit(1)
; -----------------------------------------------------------

_start:
    ; sys_read(0, buf, 32)
    xor rax, rax
    mov rdi, rax
    mov rsi, buf
    mov rdx, 32
    syscall

    ; parse => RAX = integer or -1 on error
    call parse
    test rax, rax
    js .invalid    ; if RAX < 0 => invalid input => exit(2)

    ; is_prime(RAX)
    ; if <2 => not prime => exit(1)
    cmp rax, 2
    jb .not_prime
    mov rdi, rax
    call is_prime
    test rax, rax
    jz .prime
.not_prime:
    mov rax, 60
    mov rdi, 1
    syscall
.prime:
    mov rax, 60
    xor rdi, rdi
    syscall
.invalid:
    mov rax, 60
    mov rdi, 2
    syscall

; -----------------------------------------------------------
; parse:
;   - consumes buf[] until NUL or newline
;   - returns >=0 in RAX if valid, or -1 if invalid
; -----------------------------------------------------------
parse:
    xor rax, rax
.p_loop:
    mov dl, [rsi]
    cmp dl, 0
    je .done
    cmp dl, 10
    je .done
    sub dl, '0'
    jl .err         ; anything below '0' => invalid => -1
    cmp dl, 9
    jg .err         ; anything above '9' => invalid => -1
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .p_loop
.done:
    ret
.err:
    mov rax, -1
    ret

; -----------------------------------------------------------
; is_prime(RDI):
;   Returns RAX=0 if prime, RAX=1 if not prime
;   Naive method: test divisors 2..sqrt(n)
; -----------------------------------------------------------
is_prime:
    mov rbx, rdi         ; number in rbx
    mov rcx, 2
.loop:
    ; if rcx*rcx > rbx => prime
    mov rax, rcx
    mul rcx
    ; rdx:rax = rcx^2
    cmp rdx, 0
    jne .prime
    cmp rax, rbx
    ja  .prime

    ; check if rbx % rcx == 0 => not prime
    mov rax, rbx
    xor rdx, rdx
    div rcx
    test rdx, rdx
    jz .not_prime

    inc rcx
    jmp .loop

.prime:
    xor rax, rax
    ret

.not_prime:
    mov rax, 1
    ret
