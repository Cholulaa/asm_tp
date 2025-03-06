section .data
    listening_msg     db "⏳ Listening on port 4242", 10
    listening_msg_len equ $ - listening_msg

    prompt            db "Type a command: ", 0
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
<<<<<<< HEAD
        dw 0x9210              ; Port 4242 in network byte order
        dd 0x0100007F          ; 127.0.0.1
=======
        dw 0x9210               ; Port 4242 in network byte order (4242 → 0x1092 → 0x9210)
        dd 0x0100007F          ; 127.0.0.1 in network order
>>>>>>> parent of 392cd45 (ver5)
        times 8 db 0
=======
        dw 0x9210              ; Port 4242 (network byte order)
        dd 0                   ; INADDR_ANY
        times 8 db 0           ; Padding
>>>>>>> parent of ed31b73 (cleaned up all the programs)

section .bss
    buffer  resb 1024           ; Buffer for client commands
    revbuf  resb 1024           ; Buffer for reversed string

section .text
global _start

_start:
<<<<<<< HEAD
    ; Create socket
<<<<<<< HEAD
=======
    ; Create TCP socket: socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
>>>>>>> parent of 392cd45 (ver5)
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

<<<<<<< HEAD
    ; Listen
<<<<<<< HEAD
=======
    ; Listen on socket, backlog = 10
>>>>>>> parent of 392cd45 (ver5)
    mov rdi, rbx
    mov rsi, 10
    mov rax, 50              ; sys_listen
=======
    mov rax, 50          ; sys_listen
    mov rdi, r12
    mov rsi, 5           ; backlog
>>>>>>> parent of ed31b73 (cleaned up all the programs)
    syscall

<<<<<<< HEAD
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
=======
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
>>>>>>> parent of 392cd45 (ver5)

    ; Fork to handle client concurrently
    mov rax, 57            ; sys_fork
    syscall
    cmp rax, 0
<<<<<<< HEAD
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
=======
    je child_handler
    ; Parent: close client socket and loop
>>>>>>> parent of 392cd45 (ver5)
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
<<<<<<< HEAD
<<<<<<< HEAD
    mov rdi, r12
=======
    mov rdi, r12          ; client socket
    mov rax, 1            ; sys_write
>>>>>>> parent of 392cd45 (ver5)
    lea rsi, [rel prompt]
    mov rdx, prompt_len
    syscall

    ; Read command from client into buffer
    mov rdi, r12
<<<<<<< HEAD
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
=======
    mov rax, 0            ; sys_read
>>>>>>> parent of 392cd45 (ver5)
    lea rsi, [rel buffer]
    mov rdx, 1024
    syscall
<<<<<<< HEAD
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
=======
    cmp rax, 0
    jle close_client
    mov r13, rax         ; number of bytes read
>>>>>>> parent of 392cd45 (ver5)
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
    mov rcx, cmd_ping_len
    call strcmp_n
    cmp rax, 0
    je do_ping

    ; Compare with "ECHO " (first 5 characters)
    mov rsi, buffer
    mov rdi, cmd_echo
    mov rcx, cmd_echo_len
    call strcmp_n
    cmp rax, 0
    je do_echo

    ; Compare with "REVERSE " (first 8 characters)
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
<<<<<<< HEAD
<<<<<<< HEAD
    mov rax, 1
=======
>>>>>>> parent of 392cd45 (ver5)
    syscall
    jmp client_loop

do_echo:
    ; Echo text after "ECHO "
    lea rsi, [buffer + cmd_echo_len]
    call strlen
<<<<<<< HEAD
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
=======
    mov r14, rax         ; r14 = length of text
    mov rdi, r12         ; client socket
    mov rax, 1           ; sys_write
    lea rsi, [buffer + cmd_echo_len]
    mov rdx, r14
>>>>>>> parent of 392cd45 (ver5)
    syscall
    jmp client_loop

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> parent of 5e0415c (ver12)
do_reverse:
    ; Reverse text after "REVERSE "
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
<<<<<<< HEAD
    call reverse_string
<<<<<<< HEAD
    
    ; Send reversed string
=======
    call reverse_copy
    ; Write reversed text and newline to client
>>>>>>> parent of 392cd45 (ver5)
    mov rdi, r12
    mov rax, 1
    lea rsi, [rel revbuf]
    mov rdx, r14
    syscall
<<<<<<< HEAD
    ; Calculate length of string to reverse (after "REVERSE ")
=======
cmd_reverse:
<<<<<<< HEAD
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
=======
>>>>>>> parent of 392cd45 (ver5)
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
<<<<<<< HEAD

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
=======
    ; Skip "REVERSE " (8 chars)
>>>>>>> parent of 7fb20d0 (ver13)
    mov rcx, r14
    sub rcx, 8          ; String length
    lea rsi, [buffer + 8]  ; Source
    lea rdi, [revbuf]      ; Destination
    std                    ; Set direction flag for reverse copy
    add rsi, rcx          ; Point to end of string
    dec rsi
    
.reverse_loop:
    lodsb
    stosb
    loop .reverse_loop
    cld                    ; Clear direction flag

    ; Send reversed string
    mov rax, 1
    mov rdi, r13
    lea rsi, [revbuf]
    mov rdx, r14
    sub rdx, 8
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
=======
>>>>>>> parent of 392cd45 (ver5)
