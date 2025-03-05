section .data
buffer: times 64 db 0
bin_flag: db '-b', 0

section .text
global _start

_start:
    mov r8, [rsp]
    cmp r8, 1
    jbe error
    mov rsi, [rsp+16]
    call strcmp_b
    test rax, rax
    jz check_bin
do_hex:
    mov rsi, [rsp+16]
    call parse_int
    mov rbx, rax
    call print_hex
    jmp success

check_bin:
    cmp r8, 2
    jbe error
    mov rsi, [rsp+24]
    call parse_int
    mov rbx, rax
    call print_bin
    jmp success

success:
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

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
    div rcx
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
 