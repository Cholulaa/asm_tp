section .data
    listening_msg     db "⏳ Listening on port 4242", 10
    listening_msg_len equ $ - listening_msg

    prompt            db "Type a command: ", 0
    prompt_len        equ $ - prompt

    pong              db "PONG", 10
    pong_len          equ $ - pong

    goodbye           db "Goodbye!", 10
    goodbye_len       equ $ - goodbye

    cmd_ping          db "PING", 0
    cmd_ping_len      equ $ - cmd_ping

    cmd_reverse_space db "REVERSE ", 0
    cmd_reverse_space_len equ $ - cmd_reverse_space

    cmd_exit          db "EXIT", 0
    cmd_exit_len      equ $ - cmd_exit

    newline           db 10

    server_addr:
        dw 2                    ; AF_INET
        dw 0x9210               ; Port 4242 in network byte order (4242 → 0x1092 → 0x9210)
        dd 0x0100007F          ; 127.0.0.1 in network order
        times 8 db 0

section .bss
    buffer  resb 1024           ; Buffer for client commands
    revbuf  resb 1024           ; Buffer for reversed string

section .text
global _start

_start:
    ; Create TCP socket: socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    mov rdi, 2               ; AF_INET
    mov rsi, 1               ; SOCK_STREAM
    mov rdx, 6               ; IPPROTO_TCP
    mov rax, 41              ; sys_socket
    syscall
    test rax, rax
    js exit_error
    mov rbx, rax             ; rbx = listening socket

    ; Bind socket to server_addr
    mov rdi, rbx
    lea rsi, [rel server_addr]
    mov rdx, 16
    mov rax, 49              ; sys_bind
    syscall

    ; Listen on socket, backlog = 10
    mov rdi, rbx
    mov rsi, 10
    mov rax, 50              ; sys_listen
    syscall

    ; Print listening message to stdout
    mov rdi, 1               ; stdout
    mov rax, 1               ; sys_write
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    syscall

accept_loop:
    ; Accept connection (blocking)
    mov rdi, rbx           ; listening socket
    xor rsi, rsi           ; NULL
    xor rdx, rdx           ; NULL
    mov rax, 43            ; sys_accept
    syscall
    test rax, rax
    js accept_loop         ; if error, try again
    mov r12, rax           ; r12 = client socket

    ; Fork to handle client concurrently
    mov rax, 57            ; sys_fork
    syscall
    cmp rax, 0
    je child_handler
    ; Parent: close client socket and loop
    mov rdi, r12
    mov rax, 3             ; sys_close
    syscall
    jmp accept_loop

child_handler:
    ; In child, close the listening socket
    mov rdi, rbx
    mov rax, 3             ; sys_close
    syscall

client_loop:
    ; Send prompt
    mov rdi, r12          ; client socket
    mov rax, 1            ; sys_write
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; Read command from client into buffer
    mov rdi, r12
    mov rax, 0            ; sys_read
    lea rsi, [rel buffer]
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle close_client
    mov r13, rax         ; number of bytes read
    mov byte [buffer + r13], 0

    ; Remove trailing newline if present
    mov rbx, r13
    dec rbx
    mov al, byte [buffer + rbx]
    cmp al, 10
    jne .skip_newline
    mov byte [buffer + rbx], 0
.skip_newline:

    ; Compare with "PING" (first 4 characters)
    mov rsi, buffer
    mov rdi, cmd_ping
    mov rcx, 4
    call strcmp_n
    cmp rax, 0
    je do_ping

    ; Compare with "REVERSE " (8 characters)
    mov rsi, buffer
    mov rdi, cmd_reverse_space
    mov rcx, cmd_reverse_space_len
    call strcmp_n
    cmp rax, 0
    je do_reverse

    ; Compare with "EXIT" (first 4 characters)
    mov rsi, buffer
    mov rdi, cmd_exit
    mov rcx, cmd_exit_len
    call strcmp_n
    cmp rax, 0
    je do_exit

    jmp client_loop

do_ping:
    mov rdi, r12
    mov rax, 1            ; sys_write
    lea rsi, [rel pong]
    mov rdx, pong_len
    syscall
    jmp client_loop

do_reverse:
    ; Pointer to text = buffer + cmd_reverse_space_len
    lea rsi, [buffer + cmd_reverse_space_len]
    mov rbx, r13
    dec rbx
    mov al, byte [buffer + rbx]
    cmp al, 10
    jne reverse_start
    mov byte [buffer + rbx], 0
reverse_start:
    lea rdi, [buffer + cmd_reverse_space_len]
    call strlen
    mov r14, rax         ; r14 = length of text
    lea rsi, [buffer + cmd_reverse_space_len]
    lea rdi, [rel revbuf]
    mov rcx, r14
    call reverse_copy
    ; Write reversed text and newline to client
    mov rdi, r12
    mov rax, 1
    lea rsi, [rel revbuf]
    mov rdx, r14
    syscall
    mov rdi, r12
    mov rax, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    jmp client_loop

do_exit:
    mov rdi, r12
    mov rax, 1
    lea rsi, [rel goodbye]
    mov rdx, goodbye_len
    syscall
    jmp close_client

close_client:
    mov rdi, r12
    mov rax, 3            ; sys_close
    syscall
    mov rdi, 0
    mov rax, 60           ; sys_exit
    syscall

strcmp_n:
    push rcx
.cmp_loop:
    cmp rcx, 0
    je .equal
    mov al, byte [rsi]
    mov bl, byte [rdi]
    cmp al, bl
    jne .diff
    inc rsi
    inc rdi
    dec rcx
    jmp .cmp_loop
.equal:
    xor rax, rax
    pop rcx
    ret
.diff:
    mov rax, 1
    pop rcx
    ret

strlen:
    xor rcx, rcx
.str_loop:
    cmp byte [rdi+rcx], 0
    je .done
    inc rcx
    jmp .str_loop
.done:
    mov rax, rcx
    ret

reverse_copy:
    mov rbx, rcx
    dec rbx
.rev_loop:
    xor rdx, rdx
    mov al, byte [rsi+rbx]
    mov byte [rdi], al
    inc rdi
    dec rbx
    cmp rbx, -1
    jne .rev_loop
    ret

exit_error:
    mov rdi, 1
    mov rax, 60
    syscall
