section .data

section .bss
    tampon17 resb 1024

section .text
global _start

_start:
    cmp qword [rsp], 2
    jl erreur17
    mov rsi, [rsp+16]
    xor rax, rax
boucle_convert:
    movzx rcx, byte [rsi]
    test rcx, rcx
    je fini_convert
    cmp cl, 10
    je fini_convert
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    inc rsi
    jmp boucle_convert
fini_convert:
    xor rdx, rdx
    mov rcx, 26
    div rcx
    mov r13, rdx
    mov rdi, 0
    mov rax, 0
    mov rsi, tampon17
    mov rdx, 1024
    syscall
    mov r12, rax
    mov rcx, rax
    mov rsi, tampon17
boucle_traitement:
    test rcx, rcx
    je ecrire17
    mov al, byte [rsi]
    cmp al, 'a'
    jl verif_maj
    cmp al, 'z'
    jg verif_maj
    add al, r13b
    cmp al, 'z'
    jle stocker
    sub al, 26
    jmp stocker
verif_maj:
    cmp al, 'A'
    jl stocker
    cmp al, 'Z'
    jg stocker
    add al, r13b
    cmp al, 'Z'
    jle stocker
    sub al, 26
stocker:
    mov byte [rsi], al
    inc rsi
    dec rcx
    jmp boucle_traitement
ecrire17:
    mov rdi, 1
    mov rax, 1
    mov rsi, tampon17
    mov rdx, r12
    syscall
    xor rdi, rdi
    mov rax, 60
    syscall
erreur17:
    mov rdi, 1
    mov rax, 60
    syscall
 