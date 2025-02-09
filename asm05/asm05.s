section .text
    global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz sortie_erreur

    call longueur_chaine

    mov rax, 1
    mov rdi, 1
    syscall

sortie_reussite:
    mov rax, 60
    xor rdi, rdi
    syscall

sortie_erreur:
    mov rax, 60
    mov rdi, 1
    syscall

longueur_chaine:
    xor rdx, rdx
.boucle:
    cmp byte [rsi+rdx], 0
    je .fini
    inc rdx
    jmp .boucle
.fini:
    ret
