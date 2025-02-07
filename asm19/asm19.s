section .data
myaddr:
    dw 2
    dw 0x3905
    dd 0x0100007F
    times 8 db 0

listening_msg:
    db 0xE2,0x8F,0xB3, " Listening on port 1337", 10
listening_msg_len equ $ - listening_msg

filename: db "/messages", 0

section .bss
recv_buffer resb 1024

section .text
global _start

_start:
    mov rdi, 2
    mov rsi, 2
    mov rdx, 17
    mov rax, 41
    syscall
    test rax, rax
    js exit_error
    mov rbx, rax

    mov rdi, rbx
    lea rsi, [rel myaddr]
    mov rdx, 16
    mov rax, 49
    syscall

    mov rdi, 1
    mov rax, 1
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    syscall

listen_loop:
    mov rdi, rbx
    lea rsi, [rel recv_buffer]
    mov rdx, 1024
    xor r10, r10
    xor r8, r8
    xor r9, r9
    mov rax, 45
    syscall
    cmp rax, 0
    jle listen_loop
    mov r11, rax

    lea rdi, [rel filename]
    mov rsi, 1089
    mov rdx, 420
    mov rax, 2
    syscall
    test rax, rax
    js file_error
    mov rcx, rax

    mov rdi, rcx
    mov rax, 1
    lea rsi, [rel recv_buffer]
    mov rdx, r11
    syscall

    mov rdi, rcx
    mov rax, 3
    syscall
    jmp listen_loop

file_error:
    mov rdi, rbx
    mov rax, 3
    syscall
    jmp listen_loop

exit_error:
    mov rdi, 1
    mov rax, 60
    syscall
