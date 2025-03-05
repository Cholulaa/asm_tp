section .data
msg: db "Hello Universe!", 0Ah
len: equ $ - msg

section .text
global _start

_start:
    mov r8, [rsp]
    cmp r8, 2
    jl e
    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 577
    mov rdx, 0o644
    syscall
    cmp rax, 0
    js e
    mov rbx, rax
    mov rax, 1
    mov rdi, rbx
    mov rsi, msg
    mov rdx, len
    syscall
    mov rax, 3
    mov rdi, rbx
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall
e:
    mov rax, 60
    mov rdi, 1
    syscall
 