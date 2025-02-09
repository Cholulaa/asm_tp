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
    jz fin12
    lea rdi, [tampon+rcx-1]
    cmp byte [rdi], 10
    jne inverser
    dec rcx
inverser:
    mov rsi, tampon
    lea rdi, [tampon+rcx-1]
boucle_inv:
    cmp rsi, rdi
    jge ecrire12
    mov al, [rsi]
    mov bl, [rdi]
    mov [rsi], bl
    mov [rdi], al
    inc rsi
    dec rdi
    jmp boucle_inv
ecrire12:
    mov rax, 1
    mov rdi, 1
    mov rsi, tampon
    mov rdx, rcx
    syscall
fin12:
    mov rax, 60
    xor rdi, rdi
    syscall
