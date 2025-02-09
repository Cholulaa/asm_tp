section .data
    adresse:
        dw 2
        dw 0x3905
        dd 0x0100007F
        times 8 db 0
    msg_ecoute:
        db 0xE2,0x8F,0xB3, " Listening on port 1337", 10
    lg_msg_ecoute equ $ - msg_ecoute
    nom_fichier: db "messages", 0

section .bss
    tampon_reception resb 1024

section .text
global _start

_start:
    mov rdi, 2
    mov rsi, 2
    mov rdx, 17
    mov rax, 41
    syscall
    test rax, rax
    js sortie_erreur
    mov rbx, rax
    mov rdi, rbx
    lea rsi, [rel adresse]
    mov rdx, 16
    mov rax, 49
    syscall
    mov rdi, 1
    mov rax, 1
    lea rsi, [rel msg_ecoute]
    mov rdx, lg_msg_ecoute
    syscall

boucle_ecoute:
    mov rdi, rbx
    lea rsi, [rel tampon_reception]
    mov rdx, 1024
    xor r10, r10
    xor r8, r8
    xor r9, r9
    mov rax, 45
    syscall
    cmp rax, 0
    jle boucle_ecoute
    mov r11, rax
    mov rdi, -100
    lea rsi, [rel nom_fichier]
    mov rdx, 1089
    mov r10, 420
    mov rax, 257
    syscall
    test rax, rax
    js erreur_fichier
    mov rcx, rax
    mov rdi, rcx
    mov rax, 1
    lea rsi, [rel tampon_reception]
    mov rdx, r11
    syscall
    mov rdi, rcx
    mov rax, 3
    syscall
    jmp boucle_ecoute

erreur_fichier:
    mov rdi, rbx
    mov rax, 3
    syscall
    jmp boucle_ecoute

sortie_erreur:
    mov rdi, 1
    mov rax, 60
    syscall
