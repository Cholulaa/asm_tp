section .data
    tampon db 64 dup(0)

section .text
    global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz erreur
    call conversion
    cmp rax, 2
    jb .nul
    mov rbx, rax
    dec rbx
    mul rbx
    xor rdx, rdx
    mov rcx, 2
    div rcx
    jmp .afficher

.nul:
    xor rax, rax

.afficher:
    call afficher_resultat
    mov rax, 60
    xor rdi, rdi
    syscall

erreur:
    mov rax, 60
    mov rdi, 1
    syscall

conversion:
    xor rax, rax
.boucle_conversion:
    mov dl, [rsi]
    test dl, dl
    jz .fini_conversion
    cmp dl, 10
    je .fini_conversion
    sub dl, '0'
    jl .fini_conversion
    cmp dl, 9
    jg .fini_conversion
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .boucle_conversion
.fini_conversion:
    ret

afficher_resultat:
    test rax, rax
    jnz .convertir
    mov byte [tampon], '0'
    mov rsi, tampon
    mov rdx, 1
    jmp .ecrire
.convertir:
    mov rbx, rax
    lea rdi, [tampon+63]
.boucle_conversionChiffres:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .boucle_conversionChiffres
    inc rdi
    mov rsi, rdi
    mov rdx, tampon+64
    sub rdx, rdi
.ecrire:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
