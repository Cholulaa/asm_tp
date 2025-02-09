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
    xor rbx, rbx
boucle_lecture:
    test rcx, rcx
    jz fin
    mov al, [rsi]
    inc rsi
    dec rcx
    call est_voyelle
    add rbx, rax
    jmp boucle_lecture
fin:
    mov rax, rbx
    call afficher_dec
    mov rax, 60
    xor rdi, rdi
    syscall

est_voyelle:
    cmp al, 'a'
    je rep1
    cmp al, 'e'
    je rep1
    cmp al, 'i'
    je rep1
    cmp al, 'o'
    je rep1
    cmp al, 'u'
    je rep1
    cmp al, 'y'
    je rep1
    cmp al, 'A'
    je rep1
    cmp al, 'E'
    je rep1
    cmp al, 'I'
    je rep1
    cmp al, 'O'
    je rep1
    cmp al, 'U'
    je rep1
    cmp al, 'Y'
    je rep1
    xor rax, rax
    ret
rep1:
    mov rax, 1
    ret

afficher_dec:
    test rax, rax
    jnz conv_dec
    mov byte [tampon], '0'
    mov rsi, tampon
    mov rdx, 1
    jmp ecrire_dec
conv_dec:
    mov rbx, rax
    lea rdi, [tampon+63]
boucle_dec:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [tampon+63], dl
    mov byte [rsi], dl
    dec rsi
    test rbx, rbx
    jnz boucle_dec
    inc rsi
    mov rax, tampon+64
    sub rax, rsi
copie_dec:
    mov dl, [rsi]
    mov [rdi], dl
    inc rdi
    inc rsi
    dec rax
    jnz copie_dec
ecrire_dec:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
