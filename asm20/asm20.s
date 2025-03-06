section .data
    listening_msg     db "⏳ Listening on port 4242", 10
    listening_msg_len equ $ - listening_msg

    prompt            db "Type a command: "
    prompt_len        equ $ - prompt

    pong              db "PONG", 10
    pong_len          equ $ - pong

    goodbye           db "Goodbye!", 10
    goodbye_len       equ $ - goodbye

<<<<<<< HEAD
    cmd_ping          db "PING", 0
    cmd_ping_len      equ $ - cmd_ping

    cmd_echo          db "ECHO ", 0
    cmd_echo_len      equ $ - cmd_echo

    cmd_reverse_space db "REVERSE ", 0
    cmd_reverse_space_len equ $ - cmd_reverse_space

    cmd_exit          db "EXIT", 0
    cmd_exit_len      equ $ - cmd_exit

=======
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    newline           db 10

    server_addr:
        dw 2                    ; AF_INET
<<<<<<< HEAD
        dw 0x9210              ; Port 4242 in network byte order
        dd 0x0100007F          ; 127.0.0.1
        times 8 db 0
=======
        dw 0x9210              ; Port 4242 (network byte order)
        dd 0                   ; INADDR_ANY
        times 8 db 0           ; Padding
>>>>>>> parent of ed31b73 (cleaned up all the programs)

section .bss
    buffer  resb 1024
    revbuf  resb 1024

section .text
global _start

_start:
    ; Create socket
<<<<<<< HEAD
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
=======
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
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    lea rsi, [rel server_addr]
    mov rdx, 16
    mov rax, 49              ; sys_bind
    syscall
    test rax, rax
    js exit_error

    ; Listen
<<<<<<< HEAD
    mov rdi, rbx
    mov rsi, 10              ; backlog
    mov rax, 50              ; sys_listen
=======
    mov rax, 50          ; sys_listen
    mov rdi, r12
    mov rsi, 5           ; backlog
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    syscall
    test rax, rax
    js exit_error

    ; Print listening message
<<<<<<< HEAD
    mov rdi, 1
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
    mov rax, 1
=======
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    lea rsi, [rel listening_msg]
    mov rdx, listening_msg_len
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    syscall

accept_loop:
    ; Accept connection
<<<<<<< HEAD
    mov rdi, rbx
=======
    mov rax, 43          ; sys_accept
    mov rdi, r12
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43              ; sys_accept
    syscall
    test rax, rax
    js accept_loop
<<<<<<< HEAD
    mov r12, rax             ; Save client socket

    ; Fork
    mov rax, 57              ; sys_fork
    syscall
    cmp rax, 0
    je handle_client
    
    ; Parent closes client socket and loops
=======
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
>>>>>>> parent of ed31b73 (cleaned up all the programs)
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
<<<<<<< HEAD
    mov rdi, r12
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    mov rax, 1
    syscall

    ; Read command
    mov rdi, r12
=======
    mov rax, 1
    mov rdi, r13
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; Read command
    mov rax, 0           ; sys_read
    mov rdi, r13
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    lea rsi, [rel buffer]
    mov rdx, 1024
    xor rax, rax
    syscall
    test rax, rax
<<<<<<< HEAD
    jle close_client
    mov r13, rax             ; Save bytes read
=======
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
>>>>>>> parent of ed31b73 (cleaned up all the programs)

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
<<<<<<< HEAD
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
=======
    syscall
    jmp client_loop

cmd_echo:
    ; Skip "ECHO " (5 chars)
    lea rsi, [buffer + 5]
    mov rdx, r14
    sub rdx, 5          ; Adjust length
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    mov rax, 1
    syscall
    ; Add newline
<<<<<<< HEAD
    mov rdi, r12
=======
    mov rax, 1
    mov rdi, r13
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    lea rsi, [rel newline]
    mov rdx, 1
    mov rax, 1
    syscall
    jmp client_loop

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> parent of 5e0415c (ver12)
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
<<<<<<< HEAD
    
    ; Send reversed string
    mov rdi, r12
    lea rsi, [rel revbuf]
    mov rdx, r14
    mov rax, 1
    syscall
    ; Calculate length of string to reverse (after "REVERSE ")
=======
cmd_reverse:
<<<<<<< HEAD
    ; Skip "REVERSE " (8 chars)
>>>>>>> parent of 7fb20d0 (ver13)
=======
cmd_reverse:
    ; Skip "REVERSE " (8 chars)
>>>>>>> parent of 7fb20d0 (ver13)
    mov rcx, r14
    sub rcx, 8          ; String length
    lea rsi, [buffer + 8]  ; Source
    lea rdi, [revbuf]      ; Destination
    std                    ; Set direction flag for reverse copy
    add rsi, rcx          ; Point to end of string
    dec rsi
=======
>>>>>>> parent of 5e0415c (ver12)
    
    ; Send reversed string
<<<<<<< HEAD
<<<<<<< HEAD
=======
    mov rax, 1
    mov rdi, r13
    lea rsi, [revbuf]
=======
    mov rdi, r12
    lea rsi, [rel revbuf]
>>>>>>> parent of 5e0415c (ver12)
    mov rdx, r14
    mov rax, 1
    syscall
    ; Add newline
<<<<<<< HEAD
>>>>>>> parent of 7fb20d0 (ver13)
    mov rax, 1
    mov rdi, r13
    lea rsi, [revbuf]
    mov rdx, r14
    sub rdx, 8
    syscall
    ; Add newline
=======
>>>>>>> parent of 5e0415c (ver12)
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
=======
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
>>>>>>> parent of ed31b73 (cleaned up all the programs)
