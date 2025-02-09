section .data
    tampon: times 64 db 0

section .text
global _start

_start:
    mov r8, [rsp]
    cmp r8, 4
    jl sortie_erreur
    mov rsi, [rsp+16]
    call conversion
    mov rbx, rax
    mov rsi, [rsp+24]
    call conversion
    mov rcx, rax
    mov rsi, [rsp+32]
    call conversion
    mov rdx, rax
    cmp rcx, rbx
    jle .c
    mov rbx, rcx
.c:
    cmp rdx, rbx
    jle .m
    mov rbx, rdx
.m:
    mov rax, rbx
    call afficher_nombre
    mov rax, 60
    xor rdi, rdi
    syscall
sortie_erreur:
    mov rax, 60
    mov rdi, 1
    syscall

conversion:
    xor r8, r8
    mov dl, [rsi]
    cmp dl, '-'
    jne d_label
    mov r8, 1
    inc rsi
d_label:
    xor rax, rax
l_loop:
    mov dl, [rsi]
    test dl, dl
    jz fini_conversion
    cmp dl, 10
    je fini_conversion
    sub dl, '0'
    jl fini_conversion
    cmp dl, 9
    jg fini_conversion
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp l_loop
fini_conversion:
    test r8, r8
    jz r_label
    neg rax
r_label:
    ret

afficher_nombre:
    test rax, rax
    jns positif
    mov byte [tampon], '-'
    neg rax
    lea rdi, [tampon+1]
    jmp copie
positif:
    lea rdi, [tampon]
copie:
    mov rcx, rax
    test rcx, rcx
    jnz conversion_chiffres
    mov byte [rdi], '0'
    inc rdi
    jmp ecrire
conversion_chiffres:
    lea rsi, [tampon+63]
conv_loop:
    xor rdx, rdx
    mov rax, rcx
    mov r8, 10
    div r8
    mov rcx, rax
    add rdx, '0'
    mov byte [rsi], dl
    dec rsi
    test rcx, rcx
    jnz conv_loop
    inc rsi
    mov rax, tampon+64
    sub rax, rsi
copie_fin:
    mov dl, [rsi]
    mov [rdi], dl
    inc rdi
    inc rsi
    dec rax
    jnz copie_fin
ecrire:
    mov rax, 1
    mov rsi, tampon
    sub rdi, tampon
    mov rdx, rdi
    mov rdi, 1
    syscall
    ret
 