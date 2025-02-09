section .data
    message db '1337', 0xA
    longueur_message equ $ - message

section .bss
    saisie resb 4

section .text
    global _start

_start:
    mov eax, 0
    mov edi, 0
    mov rsi, saisie
    mov edx, 4
    syscall

    mov byte [saisie + 3], 0

    movzx eax, byte [saisie]
    cmp eax, '4'
    jne .non_trouve
    movzx eax, byte [saisie + 1]
    cmp eax, '2'
    jne .non_trouve
    movzx eax, byte [saisie + 2]
    cmp eax, 0xA
    jne .non_trouve

    mov eax, 1
    mov edi, 1
    mov rsi, message
    mov edx, longueur_message
    syscall

    mov eax, 60
    xor edi, edi
    syscall

.non_trouve:
    mov eax, 60
    mov edi, 1
    syscall
