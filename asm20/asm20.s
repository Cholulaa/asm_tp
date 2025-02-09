section .data
    msg_ecoute db "⏳ Listening on port 4242", 10
    lg_msg_ecoute equ $ - msg_ecoute
    invite db "Type a command: "
    lg_invite equ $ - invite
    pong db "PONG", 10
    lg_pong equ $ - pong
    au_revoir db "Goodbye!", 10
    lg_au_revoir equ $ - au_revoir
    nouvelle_ligne db 10
    adresse_serveur:
        dw 2
        dw 0x9210
        dd 0
        times 8 db 0

section .bss
    tampon_commande resb 1024
    tampon_inverse resb 1024

section .text
global _start

_start:
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    test rax, rax
    js sortie_erreur
    mov r12, rax
    mov rax, 49
    mov rdi, r12
    lea rsi, [rel adresse_serveur]
    mov rdx, 16
    syscall
    test rax, rax
    js sortie_erreur
    mov rax, 50
    mov rdi, r12
    mov rsi, 5
    syscall
    test rax, rax
    js sortie_erreur
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg_ecoute]
    mov rdx, lg_msg_ecoute
    syscall

boucle_acceptation:
    mov rax, 43
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js boucle_acceptation
    mov r13, rax
    mov rax, 57
    syscall
    cmp rax, 0
    je gerer_client
    mov rax, 3
    mov rdi, r13
    syscall
    jmp boucle_acceptation

gerer_client:
    mov rax, 3
    mov rdi, r12
    syscall

boucle_client:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel invite]
    mov rdx, lg_invite
    syscall
    mov rax, 0
    mov rdi, r13
    lea rsi, [rel tampon_commande]
    mov rdx, 1024
    syscall
    test rax, rax
    jle sortie_client
    mov r14, rax
    dec r14
    mov byte [tampon_commande + r14], 0
    cmp dword [tampon_commande], 0x474E4950
    je cmd_ping
    cmp dword [tampon_commande], 0x54495845
    je cmd_exit
    cmp dword [tampon_commande], 0x4F484345
    je cmd_echo
    cmp dword [tampon_commande], 0x45564552
    je cmd_reverse
    jmp boucle_client

cmd_ping:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel pong]
    mov rdx, lg_pong
    syscall
    jmp boucle_client

cmd_echo:
    lea rsi, [tampon_commande + 5]
    mov rdx, r14
    sub rdx, 5
    mov rax, 1
    mov rdi, r13
    syscall
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel nouvelle_ligne]
    mov rdx, 1
    syscall
    jmp boucle_client

cmd_reverse:
    mov rcx, r14
    sub rcx, 8
    push rcx
    mov rcx, r14
    lea rdi, [tampon_inverse]
    xor rax, rax
    rep stosb
    pop rcx
    lea rsi, [tampon_commande + 8]
    add rsi, rcx
    dec rsi
.boucle_inverse:
    mov al, [rsi]
    mov [tampon_inverse], al
    dec rsi
    inc tampon_inverse
    loop .boucle_inverse
    mov rax, 1
    mov rdi, r13
    lea rsi, [tampon_inverse - rcx]
    mov rdx, r14
    sub rdx, 8
    syscall
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel nouvelle_ligne]
    mov rdx, 1
    syscall
    jmp boucle_client

cmd_exit:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel au_revoir]
    mov rdx, lg_au_revoir
    syscall
    jmp sortie_client

sortie_client:
    mov rax, 3
    mov rdi, r13
    syscall
    mov rdi, 0
    mov rax, 60
    syscall

sortie_erreur:
    mov rdi, 1
    mov rax, 60
    syscall
