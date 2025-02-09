section .data
    messageUtilisateur db '1337', 0xA
    entreeAttendue     db '42', 0

section .text
    global _start

_start:
    mov rdi, [rsp+16]
    test rdi, rdi
    jz sortieEchec
    mov rsi, entreeAttendue
    call comparerChaines
    test al, al
    jnz sortieEchec
    mov rdi, 1
    mov rax, 1
    mov rsi, messageUtilisateur
    mov rdx, 5
    syscall
    xor edi, edi
    mov rax, 60
    syscall

sortieEchec:
    mov eax, 60
    mov edi, 1
    syscall

comparerChaines:
    xor rax, rax
suivant:
    mov al, [rsi]
    cmp al, byte [rdi]
    jne nonEgale
    test al, al
    jz egale
    inc rsi
    inc rdi
    jmp suivant
egale:
    ret
nonEgale:
    mov al, 1
    ret
