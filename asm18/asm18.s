section .data
dest_addr:
    dw 2                      ; AF_INET
    dw 0x3905                 ; Port 1337 in network byte order (0x0539, little-endian: 0x3905)
    dd 0x0100007F            ; 127.0.0.1 in network byte order
    times 8 db 0
dest_len dd 16

request_msg db "Ping",0
request_len equ $ - request_msg

response_prefix db "message: ", 0

; Correct timeout message: "Timeout: no response from server"
timeout_msg db "Timeout: no response from server", 0

; Timeout structure: tv_sec = 1, tv_usec = 0
timeout:
    dq 1
    dq 0

section .bss
recv_buffer resb 1024

section .text
global _start

_start:
    ; Create UDP socket (socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))
    mov rdi, 2              ; AF_INET
    mov rsi, 2              ; SOCK_DGRAM
    mov rdx, 17             ; IPPROTO_UDP
    mov rax, 41             ; sys_socket
    syscall
    test rax, rax
    js socket_err
    mov rbx, rax            ; socket fd

    ; Set a 1-second receive timeout: setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, 16)
    mov rdi, rbx
    mov rax, 54             ; sys_setsockopt
    mov rsi, 1              ; SOL_SOCKET
    mov rdx, 20             ; SO_RCVTIMEO
    mov r10, timeout
    mov r8, 16
    syscall

    ; Send request: sendto(fd, request_msg, request_len, 0, dest_addr, 16)
    mov rdi, rbx
    mov rax, 44             ; sys_sendto
    mov rsi, request_msg
    mov rdx, request_len
    mov r10, 0              ; flags = 0
    mov r8, dest_addr
    mov r9, 16
    syscall

    ; Wait for a response: recvfrom(fd, recv_buffer, 1024, 0, NULL, NULL)
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

    ; Write "message: " to stdout
    mov rdi, 1
    mov rax, 1
    mov rsi, response_prefix
    mov rdx, 9             ; length of "message: "
    syscall

    ; Write the received response to stdout
    mov rdi, 1
    mov rax, 1
    mov rsi, recv_buffer
    mov rdx, r11
    syscall

    ; Exit successfully (exit code 0)
    xor rdi, rdi
    mov rax, 60
    syscall

timeout_label:
    ; Write timeout message to stdout (exactly "Timeout: no response from server")
    mov rdi, 1
    mov rax, 1
    mov rsi, timeout_msg
    mov rdx, 32           ; length: "Timeout: no response from server" is 32 bytes
    syscall
    ; Exit with error code 1
    mov rdi, 1
    mov rax, 60
    syscall

socket_err:
    mov rdi, 1
    mov rax, 60
    syscall
