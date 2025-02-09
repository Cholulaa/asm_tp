section .bss
    nombre resb 10

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, nombre
    mov rdx, 10
    syscall

    mov rsi, nombre
    call chaine_vers_int

    cmp rax, -1
    je retour_invalide

    test rax, 1
    jz retour_zero

retour_un:
    mov rax, 60
    mov rdi, 1
    syscall

retour_zero:
    mov rax, 60
    mov rdi, 0
    syscall

retour_invalide:
    mov rax, 60
    mov rdi, 2
    syscall

chaine_vers_int:
    xor rax, rax

.boucle:
    movzx rdx, byte [rsi]
    cmp rdx, 10
    je .fini
    cmp rdx, '0'
    jl .erreur
    cmp rdx, '9'
    jg .erreur
    sub rdx, '0'
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .boucle

.erreur:
    mov rax, -1
    ret

.fini:
    ret
