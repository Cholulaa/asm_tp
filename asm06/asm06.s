section .data
buffer: times 32 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz error
    mov rdi, [rsp+24]
    test rdi, rdi
    jz error
    call parse_int
    mov rbx, rax
    mov rsi, rdi
    call parse_int
    add rax, rbx
    call print_int
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

parse_int:
    xor r8, r8
    mov dl, [rsi]
    cmp dl, '-'
    jne .skip_sign
    mov r8, 1
    inc rsi
.skip_sign:
    xor rax, rax
.pi_loop:
    mov dl, [rsi]
    test dl, dl
    je .end_parse
    sub dl, '0'
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .pi_loop
.end_parse:
    test r8, r8
    jz .ret
    neg rax
.ret:
    ret

print_int:
    test rax, rax
    jns .positive
    mov rdi, buffer
    mov byte [rdi], '-'
    neg rax
    inc rdi
    push rdi
    call print_abs
    pop rdi
    jmp .finish
.positive:
    mov rdi, buffer
    push rdi
    call print_abs
    pop rdi
.finish:
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall
    ret

print_abs:
    mov rbx, rax
    cmp rbx, 0
    jne .convert
    mov byte [rdi], '0'
    add rdi, 1
    jmp .done
.convert:
    add rdi, 31
.pa_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .pa_loop
    inc rdi
.done:
    mov rax, buffer+32
    sub rax, rdi
    ret
