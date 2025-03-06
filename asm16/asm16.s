section .data
    elf_magic dd 0x464C457F
    expected  dd 0x37333331
    replacement db "H4CK"

section .text
    global _start

_start:
    cmp qword [rsp], 2
    jl .error

    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 2
    xor rdx, rdx
    syscall

    test rax, rax
    js .error
    mov rbx, rax

    mov rdi, rax
    xor rax, rax
    mov rsi, buffer
    mov rdx, 4
    syscall

    cmp rax, 4
    jne .close_error

    mov eax, [buffer]
    cmp eax, [elf_magic]
    jne .close_error

    mov rdi, rbx
    mov rax, 8
    mov rsi, 0x2000
    xor rdx, rdx
    syscall

    cmp rax, 0x2000
    jne .close_error

    mov rdi, rbx
    xor rax, rax
    mov rsi, buffer
    mov rdx, 4
    syscall

    cmp rax, 4
    jne .close_error

    mov eax, [buffer]
    cmp eax, [expected]
    jne .close_error

    mov rdi, rbx
    mov rax, 8
    mov rsi, 0x2000
    xor rdx, rdx
    syscall

    cmp rax, 0x2000
    jne .close_error

    mov rdi, rbx
    mov rax, 1
    mov rsi, replacement
    mov rdx, 4
    syscall

    cmp rax, 4
    jne .close_error

    mov rdi, rbx
    mov rax, 3
    syscall

    xor rdi, rdi
    mov rax, 60
    syscall

.close_error:
    mov rdi, rbx
    mov rax, 3
    syscall
.error:
    mov rdi, 1
    mov rax, 60
    syscall

section .bss
<<<<<<< HEAD
    tampon16 resb 16
 
=======
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    buffer resb 16
