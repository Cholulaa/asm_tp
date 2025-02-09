section .data
    tampon: times 64 db 0

section .text
global _start

_start:
    xor rax, rax
    mov rdi, rax
    mov rsi, tampon
    mov rdx, 64
    syscall
    mov rcx, rax
    test rcx, rcx
    jz pal
    cmp byte [tampon+rcx-1], 10
    jne skip
    dec rcx
    cmp rcx, 0
    je pal
skip:
    xor rsi, rsi
    mov rdi, rcx
    dec rdi
boucle_cmp:
    cmp rsi, rdi
    jge pal
    mov al, [tampon+rsi]
    mov bl, [tampon+rdi]
    cmp al, bl
    jne np
    inc rsi
    dec rdi
    jmp boucle_cmp
pal:
    mov rax, 60
    xor rdi, rdi
    syscall
np:
    mov rax, 60
    mov rdi, 1
    syscall
 