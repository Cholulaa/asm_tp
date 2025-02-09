section .bss
    tampon resb 32

section .text
global _start

_start:
    xor rax, rax
    mov rdi, rax
    mov rsi, tampon
    mov rdx, 32
    syscall
    call conversion
    test rax, rax
    js invalide
    cmp rax, 2
    jb pas_premier
    mov rdi, rax
    call est_premier
    test rax, rax
    jz premier
pas_premier:
    mov rax, 60
    mov rdi, 1
    syscall
premier:
    mov rax, 60
    xor rdi, rdi
    syscall
invalide:
    mov rax, 60
    mov rdi, 2
    syscall

conversion:
    xor rax, rax
boucle:
    mov dl, [rsi]
    cmp dl, 0
    je fini
    cmp dl, 10
    je fini
    sub dl, '0'
    jl erreur
    cmp dl, 9
    jg erreur
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp boucle
fini:
    ret
erreur:
    mov rax, -1
    ret

est_premier:
    mov rbx, rdi
    mov rcx, 2
boucle_p:
    mov rax, rcx
    mul rcx
    cmp rdx, 0
    jne suite
    cmp rax, rbx
    ja suite
    mov rax, rbx
    xor rdx, rdx
    div rcx
    test rdx, rdx
    jz np
    inc rcx
    jmp boucle_p
suite:
    xor rax, rax
    ret
np:
    mov rax, 1
    ret
