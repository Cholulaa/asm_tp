section .data
    listening_msg     db "⏳ Listening on port 4242", 10
    listening_msg_len equ $ - listening_msg

    prompt            db "Type a command: "
    prompt_len        equ $ - prompt

    pong              db "PONG", 10
    pong_len          equ $ - pong

    goodbye           db "Goodbye!", 10
    goodbye_len       equ $ - goodbye

    newline           db 10

    server_addr:
        dw 2                    ; AF_INET
        dw 0x9210              ; Port 4242 (network byte order)
        dd 0                   ; INADDR_ANY
        times 8 db 0           ; Padding

section .bss
    buffer  resb 1024
    revbuf  resb 1024

section .text
global _start

_start:
    ; Create socket
    mov rax, 41          ; sys_socket
    mov rdi, 2           ; AF_INET
    mov rsi, 1           ; SOCK_STREAM
    mov rdx, 0           ; protocol
    syscall
    test rax, rax
    js exit_error
    mov r12, rax         ; Save socket fd

    ; Bind socket
    mov rax, 49          ; sys_bind
    mov rdi, r12
    lea rsi, [rel server_addr]
    mov rdx, 16
    syscall
    test rax, rax
    js exit_error

    ; Listen
    mov rax, 50          ; sys_listen
    mov rdi, r12
    mov rsi, 5           ; backlog
    syscall
    test rax, rax
    js exit_error

    ; Print listening message
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    syscall

accept_loop:
    ; Accept connection
    mov rax, 43          ; sys_accept
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js accept_loop
    mov r13, rax         ; Save client socket

    ; Fork
    mov rax, 57          ; sys_fork
    syscall
    cmp rax, 0
    je handle_client

    ; Parent: close client socket and continue accepting
    mov rax, 3           ; sys_close
    mov rdi, r13
    syscall
    jmp accept_loop

handle_client:
    ; Child: close server socket
    mov rax, 3
    mov rdi, r12
    syscall

client_loop:
    ; Send prompt
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; Read command
    mov rax, 0           ; sys_read
    mov rdi, r13
    lea rsi, [rel buffer]
    mov rdx, 1024
    syscall
    test rax, rax
    jle client_exit
    mov r14, rax         ; Save bytes read

    ; Remove newline if present
    dec r14
    mov byte [buffer + r14], 0

    ; Check for commands
    cmp dword [buffer], 0x474E4950  ; "PING"
    je cmd_ping

    cmp dword [buffer], 0x54495845  ; "EXIT"
    je cmd_exit

    cmp dword [buffer], 0x4F484345  ; "ECHO"
    je cmd_echo

    cmp dword [buffer], 0x45564552  ; "REVE"
    je cmd_reverse

    jmp client_loop

cmd_ping:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel pong]
    mov rdx, pong_len
    syscall
    jmp client_loop

cmd_echo:
    ; Skip "ECHO " (5 chars)
    lea rsi, [buffer + 5]
    mov rdx, r14
    sub rdx, 5          ; Adjust length
    mov rax, 1
    mov rdi, r13
    syscall
    ; Add newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    jmp client_loop

cmd_reverse:
    ; Calculate length of string to reverse (after "REVERSE ")
    mov rcx, r14
    sub rcx, 8          ; Skip "REVERSE " prefix
    
    ; Clear destination buffer
    push rcx
    mov rcx, r14
    lea rdi, [revbuf]
    xor rax, rax
    rep stosb
    pop rcx
    
    ; Setup source and destination
    lea rsi, [buffer + 8]  ; Source: after "REVERSE "
    lea rdi, [revbuf]      ; Destination
    add rsi, rcx          ; Point to end of source string
    dec rsi

.reverse_loop:
    mov al, [rsi]         ; Get character from end
    mov [rdi], al         ; Store at beginning
    dec rsi               ; Move backward in source
    inc rdi               ; Move forward in destination
    loop .reverse_loop

    ; Send reversed string
    mov rax, 1           ; sys_write
    mov rdi, r13         ; client socket
    lea rsi, [revbuf]    ; reversed string
    mov rdx, r14         ; length
    sub rdx, 8           ; subtract "REVERSE " length
    syscall
    
    ; Add newline
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    jmp client_loop

cmd_exit:
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel goodbye]
    mov rdx, goodbye_len
    syscall

client_exit:
    mov rax, 3           ; sys_close
    mov rdi, r13
    syscall
    mov rax, 60          ; sys_exit
    xor rdi, rdi
    syscall

exit_error:
    mov rax, 60          ; sys_exit
    mov rdi, 1
    syscall