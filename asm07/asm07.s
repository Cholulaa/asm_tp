section .data
buf: times 32 db 0

section .text
global _start

_start:
    xor rax, rax
    mov rdi, rax
    mov rsi, buf
    mov rdx, 32
    syscall
    call parse
    test rax, rax
    js invalid
    cmp rax, 2
    jb not_prime
    mov rdi, rax
    call is_prime
    test rax, rax
    jz prime
not_prime:
    mov rax, 60
    mov rdi, 1
    syscall
prime:
    mov rax, 60
    xor rdi, rdi
    syscall
invalid:
    mov rax, 60
    mov rdi, 2
    syscall

parse:
    xor rax, rax
p_loop:
    mov dl, [rsi]
    cmp dl, 0
    je done
    cmp dl, 10
    je done
    sub dl, '0'
    jl err
    cmp dl, 9
    jg err
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp p_loop
done:
    ret
err:
    mov rax, -1
    ret

is_prime:
    mov rbx, rdi
    mov rcx, 2
lp:
    mov rax, rcx
    mul rcx
    cmp rdx, 0
    jne p
    cmp rax, rbx
    ja p
    mov rax, rbx
    xor rdx, rdx
    div rcx
    test rdx, rdx
    jz np
    inc rcx
    jmp lp
p:
    xor rax, rax
    ret
np:
    mov rax, 1
    ret
