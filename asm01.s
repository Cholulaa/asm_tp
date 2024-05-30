section .data
    message db "1337", 0x0A

section .text
global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [message]
    mov rdx, 5
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall
