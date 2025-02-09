section .data
    tampon db 20 dup(0)

section .text
    global _start

_start:
    pop rcx
    cmp rcx, 3
    jne sortie_echec
    pop rcx
    pop rcx
    mov rdi, rcx
    call chaine_vers_int
    mov r12, rax
    pop rcx
    mov rdi, rcx
    call chaine_vers_int
    add rax, r12
    mov rdi, rax
    mov rsi, tampon
    call entier_vers_chaine
    mov rdi, tampon
    call longueur_chaine
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, tampon
    syscall
    mov [tampon], byte 0xA
    mov rax, 1
    mov rdi, 1
    mov rsi, tampon
    mov rdx, 1
    syscall
    jmp sortie_reussite

chaine_vers_int:
    push rbx
    mov rsi, rdi
    xor rax, rax
    mov rbx, 1
    cmp byte [rsi], '-'
    jne .processus
    inc rsi
    neg rbx
.processus:
    movzx rcx, byte [rsi]
    test rcx, rcx
    jz .fin
    cmp rcx, '0'
    jb .fin
    cmp rcx, '9'
    ja .fin
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .processus
.fin:
    imul rax, rbx
    pop rbx
    ret

entier_vers_chaine:
    push rbp
    mov rbp, rsp
    push rbx
    test rdi, rdi
    jns .positif
    neg rdi
    mov byte [rsi], '-'
    inc rsi
.positif:
    mov rax, rdi
    mov rbx, 10
    mov rcx, 0
.division:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .division
.construction:
    pop rax
    add al, '0'
    mov [rsi], al
    inc rsi
    dec rcx
    jnz .construction
    mov byte [rsi], 0
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

longueur_chaine:
    xor rax, rax
.boucle:
    cmp byte [rdi+rax], 0
    je .fin_longueur
    inc rax
    jmp .boucle
.fin_longueur:
    ret

sortie_reussite:
    mov rax, 60
    xor rdi, rdi
    syscall

sortie_echec:
    mov rax, 60
    mov rdi, 1
    syscall
