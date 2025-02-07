section .data
    listening_msg     db "⏳ Listening on port 4242", 10
    listening_msg_len equ $ - listening_msg

    prompt            db "Type a command: "
    prompt_len        equ $ - prompt

    pong              db "PONG", 10
    pong_len          equ $ - pong

    goodbye           db "Goodbye!", 10
    goodbye_len       equ $ - goodbye

    cmd_ping          db "PING", 0
    cmd_ping_len      equ $ - cmd_ping

    cmd_echo          db "ECHO ", 0
    cmd_echo_len      equ $ - cmd_echo

    cmd_reverse_space db "REVERSE ", 0
    cmd_reverse_space_len equ $ - cmd_reverse_space

    cmd_exit          db "EXIT", 0
    cmd_exit_len      equ $ - cmd_exit

    newline           db 10

    server_addr:
        dw 2                    ; AF_INET
        dw 0x9210              ; Port 4242 in network byte order
        dd 0x0100007F          ; 127.0.0.1
        times 8 db 0

section .bss
    buffer  resb 1024
    revbuf  resb 1024

section .text
global _start

_start:
    ; Create socket
    mov rdi, 2               ; AF_INET
    mov rsi, 1               ; SOCK_STREAM
    mov rdx, 6               ; IPPROTO_TCP
    mov rax, 41              ; sys_socket
    syscall
    test rax, rax
    js exit_error
    mov rbx, rax             ; Save socket fd

    ; Bind
    mov rdi, rbx
    lea rsi, [rel server_addr]
    mov rdx, 16
    mov rax, 49              ; sys_bind
    syscall
    test rax, rax
    js exit_error

    ; Listen
    mov rdi, rbx
    mov rsi, 10              ; backlog
    mov rax, 50              ; sys_listen
    syscall
    test rax, rax
    js exit_error

    ; Print listening message
    mov rdi, 1
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    mov rax, 1
    syscall

accept_loop:
    ; Accept connection
    mov rdi, rbx
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43              ; sys_accept
    syscall
    test rax, rax
    js accept_loop
    mov r12, rax             ; Save client socket

    ; Fork
    mov rax, 57              ; sys_fork
    syscall
    cmp rax, 0
    je handle_client
    
    ; Parent closes client socket and loops
    mov rdi, r12
    mov rax, 3
    syscall
    jmp accept_loop

handle_client:
    ; Child closes listening socket
    mov rdi, rbx
    mov rax, 3
    syscall

client_loop:
    ; Send prompt
    mov rdi, r12
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    mov rax, 1
    syscall

    ; Read command
    mov rdi, r12
    lea rsi, [rel buffer]
    mov rdx, 1024
    xor rax, rax
    syscall
    test rax, rax
    jle close_client
    mov r13, rax             ; Save bytes read

    ; Remove newline
    dec r13
    mov byte [buffer + r13], 0

    ; Check commands
    lea rdi, [rel buffer]
    lea rsi, [rel cmd_ping]
    mov rdx, cmd_ping_len
    call strcmp
    test rax, rax
    jz do_ping

    lea rdi, [rel buffer]
    lea rsi, [rel cmd_echo]
    mov rdx, cmd_echo_len
    call strncmp
    test rax, rax
    jz do_echo

    lea rdi, [rel buffer]
    lea rsi, [rel cmd_reverse_space]
    mov rdx, cmd_reverse_space_len
    call strncmp
    test rax, rax
    jz do_reverse

    lea rdi, [rel buffer]
    lea rsi, [rel cmd_exit]
    mov rdx, cmd_exit_len
    call strcmp
    test rax, rax
    jz do_exit

    jmp client_loop

do_ping:
    mov rdi, r12
    lea rsi, [rel pong]
    mov rdx, pong_len
    mov rax, 1
    syscall
    jmp client_loop

do_echo:
    ; Skip "ECHO " prefix
    lea rdi, [rel buffer + cmd_echo_len]
    call strlen
    mov rdx, rax
    mov rdi, r12
    lea rsi, [rel buffer + cmd_echo_len]
    mov rax, 1
    syscall
    ; Add newline
    mov rdi, r12
    lea rsi, [rel newline]
    mov rdx, 1
    mov rax, 1
    syscall
    jmp client_loop

do_reverse:
    ; Get string after "REVERSE "
    lea rdi, [rel buffer + cmd_reverse_space_len]
    call strlen
    mov r14, rax              ; Save length
    
    ; Copy to revbuf in reverse
    lea rsi, [rel buffer + cmd_reverse_space_len]
    lea rdi, [rel revbuf]
    mov rcx, r14
    call reverse_string
    
    ; Send reversed string
    mov rdi, r12
    lea rsi, [rel revbuf]
    mov rdx, r14
    mov rax, 1
    syscall
    ; Add newline
    mov rdi, r12
    lea rsi, [rel newline]
    mov rdx, 1
    mov rax, 1
    syscall
    jmp client_loop

do_exit:
    mov rdi, r12
    lea rsi, [rel goodbye]
    mov rdx, goodbye_len
    mov rax, 1
    syscall

close_client:
    mov rdi, r12
    mov rax, 3               ; sys_close
    syscall
    xor rdi, rdi
    mov rax, 60              ; sys_exit
    syscall

exit_error:
    mov rdi, 1
    mov rax, 60
    syscall

; String comparison
strcmp:
    xor rcx, rcx
.loop:
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    test al, al
    jz .check_end
    cmp al, bl
    jne .not_equal
    inc rcx
    jmp .loop
.check_end:
    test bl, bl
    jz .equal
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret

; Compare n bytes
strncmp:
    xor rcx, rcx
.loop:
    cmp rcx, rdx
    je .equal
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    test al, al
    jz .check_end
    cmp al, bl
    jne .not_equal
    inc rcx
    jmp .loop
.check_end:
    test bl, bl
    jz .equal
.not_equal:
    mov rax, 1
    ret
.equal:
    xor rax, rax
    ret

; Get string length
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Reverse string
reverse_string:
    push rsi
    push rdi
    push rcx
    dec rcx
.loop:
    mov al, [rsi + rcx]
    mov [rdi], al
    inc rdi
    dec rcx
    cmp rcx, -1
    jne .loop
    pop rcx
    pop rdi
    pop rsi
    ret