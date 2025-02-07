section .data
dest_addr:
    dw 2                      ; AF_INET
    dw 0x3905                 ; Port 1337 (0x0539 in network order; little-endian: 0x3905)
    dd 0x0100007F            ; 127.0.0.1 (network order)
    times 8 db 0
dest_len dd 16

request_msg db "Ping",0
request_len equ $ - request_msg

response_prefix db "message: ", 0
timeout_msg     db "Timeout: no response from server", 11, 0

timeout:
    dq 1                    ; tv_sec = 1
    dq 0                    ; tv_usec = 0

section .bss
recv_buffer resb 1024

section .text
global _start

_start:
    ; socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    mov rdi, 2              ; AF_INET
    mov rsi, 2              ; SOCK_DGRAM
    mov rdx, 17             ; IPPROTO_UDP
    mov rax, 41             ; sys_socket
    syscall
    test rax, rax
    js socket_err
    mov rbx, rax            ; socket fd

    ; setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, 16)
    mov rdi, rbx
    mov rax, 54             ; sys_setsockopt
    mov rsi, 1              ; SOL_SOCKET
    mov rdx, 20             ; SO_RCVTIMEO
    mov r10, timeout
    mov r8, 16
    syscall

    ; sendto(fd, request_msg, request_len, 0, dest_addr, 16)
    mov rdi, rbx
    mov rax, 44             ; sys_sendto
    mov rsi, request_msg
    mov rdx, request_len
    mov r10, 0              ; flags = 0
    mov r8, dest_addr
    mov r9, 16
    syscall

    ; recvfrom(fd, recv_buffer, 1024, 0, NULL, NULL)
    mov rdi, rbx
    mov rax, 45             ; sys_recvfrom
    mov rsi, recv_buffer
    mov rdx, 1024
    mov r10, 0
    mov r8, 0
    mov r9, 0
    syscall
    cmp rax, 0
    jl timeout_label
    mov r11, rax           ; save number of bytes received

    ; write "message: " to stdout
    mov rdi, 1
    mov rax, 1
    mov rsi, response_prefix
    mov rdx, 9             ; length of "message: "
    syscall

    ; write the received response to stdout
    mov rdi, 1
    mov rax, 1
    mov rsi, recv_buffer
    mov rdx, r11
    syscall

    ; exit(0)
    xor rdi, rdi
    mov rax, 60
    syscall

timeout_label:
    ; write timeout message to stdout
    mov rdi, 1
    mov rax, 1
    mov rsi, timeout_msg
    mov rdx, 31            ; length of "Timeout: no response from server\n"
    syscall
    ; exit(1)
    mov rdi, 1
    mov rax, 60
    syscall

socket_err:
    mov rdi, 1
    mov rax, 60
    syscall
