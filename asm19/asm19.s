section .data
myaddr:
    dw 2                      ; AF_INET
    dw 0x3905                 ; Port 1337 (htons(1337)=0x3905)
    dd 0x0100007F            ; 127.0.0.1 (in network order)
    times 8 db 0

listening_msg:
    db 0xE2,0x8F,0xB3, " Listening on port 1337", 10
listening_msg_len equ $ - listening_msg

filename: db "messages", 0

section .bss
recv_buffer resb 1024

section .text
global _start

_start:
    ; Create UDP socket: socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    mov rdi, 2              ; AF_INET
    mov rsi, 2              ; SOCK_DGRAM
    mov rdx, 17             ; IPPROTO_UDP
    mov rax, 41             ; sys_socket
    syscall
    test rax, rax
    js exit_error
    mov rbx, rax            ; save socket fd in rbx

    ; Bind socket to our address (127.0.0.1:1337)
    mov rdi, rbx
    lea rsi, [rel myaddr]
    mov rdx, 16
    mov rax, 49             ; sys_bind
    syscall

    ; Print startup message to stdout
    mov rdi, 1              ; stdout
    mov rax, 1              ; sys_write
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    syscall

listen_loop:
    ; Receive UDP packet
    mov rdi, rbx
    lea rsi, [rel recv_buffer]
    mov rdx, 1024
    xor r10, r10            ; flags = 0
    xor r8, r8              ; no src address pointer
    xor r9, r9              ; no src addr length pointer
    mov rax, 45             ; sys_recvfrom
    syscall
    cmp rax, 0
    jle listen_loop         ; if no data/error, keep listening
    mov r11, rax            ; r11 = number of bytes received

    ; Open (or create) file "messages" for appending using sys_openat (257)
    mov rdi, -100           ; AT_FDCWD
    lea rsi, [rel filename]
    mov rdx, 1089           ; O_WRONLY | O_CREAT | O_APPEND
    mov r10, 420            ; mode 0644
    mov rax, 257            ; sys_openat
    syscall
    test rax, rax
    js file_error
    mov rcx, rax            ; file descriptor for the file

    ; Write the received message to file
    mov rdi, rcx
    mov rax, 1              ; sys_write
    lea rsi, [rel recv_buffer]
    mov rdx, r11
    syscall

    ; Close the file
    mov rdi, rcx
    mov rax, 3              ; sys_close
    syscall

    jmp listen_loop

file_error:
    mov rdi, rbx
    mov rax, 3              ; sys_close
    syscall
    jmp listen_loop

exit_error:
    mov rdi, 1              ; exit(1)
    mov rax, 60             ; sys_exit
    syscall
