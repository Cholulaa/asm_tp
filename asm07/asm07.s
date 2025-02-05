section .data
buf: times 32 db 0

section .text
global _start

; Program:
;  1) Reads up to 32 bytes from stdin into 'buf'
;  2) parse() => RAX = integer
;  3) if prime => return 0, else 1
;  4) exit with that code

_start:
    xor rax, rax        ; sys_read
    mov rdi, rax        ; stdin = 0
    mov rsi, buf
    mov rdx, 32
    syscall

    call parse
    mov rdi, rax        ; store input in RDI for prime check

    ; is_prime(RDI) => RAX=0 if prime, 1 if not
    call is_prime

    ; sys_exit(RAX)
    mov rdi, rax
    mov rax, 60
    syscall

; parse => RAX = integer from buf
parse:
    xor rax, rax
parse_loop:
    mov dl, [rsi]
    cmp dl, 0
    je parse_done
    cmp dl, 10
    je parse_done
    sub dl, '0'
    jl parse_done
    cmp dl, 9
    jg parse_done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp parse_loop
parse_done:
    ret

; is_prime(RDI):
;   RDI = input number
;   RAX = 0 if prime, 1 if not
is_prime:
    cmp rdi, 2
    jb  not_prime        ; <2 => not prime

    ; We'll do a naive loop from 2..(RDI-1) or up to sqrt(RDI) (whichever).
    ; For brevity, let's do up to sqrt(RDI).
    ; We store RDI in RBX, use RCX as loop variable: 2.. up to sqrt(RBX)
    mov rbx, rdi
    mov rcx, 2
prime_loop:
    ; if rcx*rcx > rbx => prime
    mov rax, rcx
    mul rcx              ; 128-bit multiply: RDX:RAX = RCX^2
    cmp rdx, 0
    jne prime_yes        ; overflow => definitely bigger than rbx => prime
    cmp rax, rbx
    ja  prime_yes

    ; check divisibility
    mov rax, rbx
    xor rdx, rdx
    div rcx
    test rdx, rdx
    jz not_prime         ; remainder=0 => not prime

    inc rcx
    jmp prime_loop

prime_yes:
    xor rax, rax
    ret

not_prime:
    mov rax, 1
    ret
