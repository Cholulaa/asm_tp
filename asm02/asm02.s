section .data
    message db '1337', 0xA
    message_len equ $ - message

section .bss
    user_input resb 4

section .text
    global _start

_start:
    mov eax, 0
    mov edi, 0
    mov rsi, user_input
    mov edx, 4
    syscall

    mov byte [user_input + 3], 0

    movzx eax, byte [user_input]
    cmp eax, '4'
    jne .not_found
    movzx eax, byte [user_input + 1]
    cmp eax, '2'
    jne .not_found
    movzx eax, byte [user_input + 2]
    cmp eax, 0xA
    jne .not_found

    mov eax, 1
    mov edi, 1
    mov rsi, message
    mov edx, message_len
    syscall

    mov eax, 60
    xor edi, edi
    syscall

.not_found:
    mov eax, 60
    mov edi, 1
    syscall
