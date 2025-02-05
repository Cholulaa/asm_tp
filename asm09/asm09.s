section .data
buffer: times 64 db 0
bin_flag: db '-b', 0

section .text
global _start

; asm09:
;   Usage:
;     ./asm09 [ -b ] <number>
;   If "-b" is present, convert <number> to binary.
;   Otherwise, convert <number> to hex (uppercase).
;   Return 0 on success, or 1 on error.
;
; Examples:
;   ./asm09 15      -> F
;   ./asm09 -b 15   -> 1111

_start:
    ; [rsp+0]  = argc
    ; [rsp+8]  = &argv[0]
    ; [rsp+16] = &argv[1]
    ; [rsp+24] = &argv[2]
    ; ...

    mov r8, [rsp]         ; r8 = argc
    cmp r8, 1
    jbe error             ; if argc <= 1 => no parameter => error

    mov rsi, [rsp+16]     ; rsi -> argv[1]
    call strcmp_b         ; compare argv[1] with "-b"
    test rax, rax
    jz check_bin          ; if rax=0 => argv[1] == "-b"
; else => do hex
do_hex:
    ; parse argv[1], then print hex
    mov rsi, [rsp+16]
    call parse_int
    mov rbx, rax
    call print_hex
    jmp success

check_bin:
    ; we have "-b" => check if we have a second argument
    cmp r8, 2
    jbe error
    mov rsi, [rsp+24]
    call parse_int
    mov rbx, rax
    call print_bin
    jmp success

; --------------------------------------------------
; success => exit(0)
success:
    mov rax, 60
    xor rdi, rdi
    syscall

; --------------------------------------------------
; error => exit(1)
error:
    mov rax, 60
    mov rdi, 1
    syscall


; --------------------------------------------------
; strcmp_b:
;   RSI => pointer to the incoming string
;   Compare with the literal '-b'
;   Return 0 if match, else non-zero
; --------------------------------------------------
strcmp_b:
    push rdi
    mov rdi, bin_flag
.loop_cmp:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .diff
    test al, al
    jz .same
    inc rsi
    inc rdi
    jmp .loop_cmp
.diff:
    mov rax, 1
    pop rdi
    ret
.same:
    xor rax, rax
    pop rdi
    ret

; --------------------------------------------------
; parse_int:
;   RSI => pointer to ASCII decimal
;   Convert to a non-negative integer in RAX
;   (Stops on non-digit or end)
; --------------------------------------------------
parse_int:
    xor rax, rax
.p_loop:
    mov dl, [rsi]
    test dl, dl
    jz .done
    cmp dl, 10
    je .done
    sub dl, '0'
    jl .done
    cmp dl, 9
    jg .done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .p_loop
.done:
    ret

; --------------------------------------------------
; print_hex:
;   RBX => value to print in uppercase hex
; --------------------------------------------------
print_hex:
    test rbx, rbx
    jnz .convert
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp .write
.convert:
    mov rax, rbx
    lea rdi, [buffer+63]
.hex_loop:
    xor rdx, rdx
    mov rcx, 16
    div rcx          ; RAX=quotient, RDX=remainder
    cmp rdx, 9
    jg .alpha
    add rdx, '0'
    jmp .store
.alpha:
    add rdx, 'A' - 10
.store:
    mov byte [rdi], dl
    dec rdi
    test rax, rax
    jnz .hex_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
.write:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

; --------------------------------------------------
; print_bin:
;   RBX => value to print in binary
; --------------------------------------------------
print_bin:
    test rbx, rbx
    jnz .conv_bin
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp .w_bin
.conv_bin:
    mov rax, rbx
    lea rdi, [buffer+63]
.bin_loop:
    xor rdx, rdx
    mov rcx, 2
    div rcx
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rax, rax
    jnz .bin_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
.w_bin:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
