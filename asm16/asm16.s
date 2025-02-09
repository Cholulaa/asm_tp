section .data
    elf_magic dd 0x464C457F
    attendu   dd 0x37333331
    remplacement db "H4CK"

section .text
global _start

_start:
    cmp qword [rsp], 2
    jl erreur16
    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 2
    xor rdx, rdx
    syscall
    test rax, rax
    js erreur16
    mov rbx, rax
    mov rdi, rax
    xor rax, rax
    mov rsi, tampon16
    mov rdx, 4
    syscall
    cmp rax, 4
    jne fermeture16
    mov eax, [tampon16]
    cmp eax, [elf_magic]
    jne fermeture16
    mov rdi, rbx
    mov rax, 8
    mov rsi, 0x2000
    xor rdx, rdx
    syscall
    cmp rax, 0x2000
    jne fermeture16
    mov rdi, rbx
    xor rax, rax
    mov rsi, tampon16
    mov rdx, 4
    syscall
    cmp rax, 4
    jne fermeture16
    mov eax, [tampon16]
    cmp eax, [attendu]
    jne fermeture16
    mov rdi, rbx
    mov rax, 8
    mov rsi, 0x2000
    xor rdx, rdx
    syscall
    cmp rax, 0x2000
    jne fermeture16
    mov rdi, rbx
    mov rax, 1
    mov rsi, remplacement
    mov rdx, 4
    syscall
    cmp rax, 4
    jne fermeture16
    mov rdi, rbx
    mov rax, 3
    syscall
    xor rdi, rdi
    mov rax, 60
    syscall
fermeture16:
    mov rdi, rbx
    mov rax, 3
    syscall
erreur16:
    mov rdi, 1
    mov rax, 60
    syscall

section .bss
    tampon16 resb 16
