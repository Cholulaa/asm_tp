section .data
buffer: times 64 db 0

section .text
global _start

_start:
    xor rax, rax
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 64
    syscall
    mov rcx, rax
    test rcx, rcx
    jz pal
    cmp byte [buffer + rcx - 1], 10
    jne skip
    dec rcx
    cmp rcx, 0
    je pal
skip:
    xor rsi, rsi
    mov rdi, rcx
    dec rdi
loopcmp:
    cmp rsi, rdi
    jge pal
    mov al, [buffer + rsi]
    mov bl, [buffer + rdi]
    cmp al, bl
    jne np
    inc rsi
    dec rdi
    jmp loopcmp
pal:
    mov rax, 60
    xor rdi, rdi
    syscall
np:
    mov rax, 60
    mov rdi, 1
    syscall
 