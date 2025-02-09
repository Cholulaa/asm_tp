section .data
    dest_addr:
        dw 2
        dw 0x3905
        dd 0x0100007F
        times 8 db 0
    dest_len dd 16
    req_msg db "Ping", 0
    req_len equ $ - req_msg
    prefix_resp db "message: ", 0
    timeout_msg db "Timeout: no response from server", 0
    timeout:
        dq 1
        dq 0

section .bss
    tampon18 resb 1024

section .text
global _start

_start:
    mov rdi, 2
    mov rsi, 2
    mov rdx, 17
    mov rax, 41
    syscall
    test rax, rax
    js sock_err
    mov rbx, rax
    mov rdi, rbx
    mov rax, 54
    mov rsi, 1
    mov rdx, 20
    mov r10, timeout
    mov r8, 16
    syscall
    mov rdi, rbx
    mov rax, 44
    mov rsi, req_msg
    mov rdx, req_len
    mov r10, 0
    mov r8, dest_addr
    mov r9, 16
    syscall
    mov rdi, rbx
    mov rax, 45
    mov rsi, tampon18
    mov rdx, 1024
    mov r10, 0
    mov r8, 0
    mov r9, 0
    syscall
    cmp rax, 0
    jl timeout_label
    mov r11, rax
    mov rdi, 1
    mov rax, 1
    mov rsi, prefix_resp
    mov rdx, 9
    syscall
    mov rdi, 1
    mov rax, 1
    mov rsi, tampon18
    mov rdx, r11
    syscall
    xor rdi, rdi
    mov rax, 60
    syscall
timeout_label:
    mov rdi, 1
    mov rax, 1
    mov rsi, timeout_msg
    mov rdx, 32
    syscall
    mov rdi, 1
    mov rax, 60
    syscall
sock_err:
    mov rdi, 1
    mov rax, 60
    syscall
