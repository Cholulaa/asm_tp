section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz e
    mov rdi, [rsp+24]
    test rdi, rdi
    jz e
    call parse_int
    mov rbx, rax
    mov rsi, rdi
    call parse_int
    add rax, rbx
    call print_int
    mov rax, 60
    xor rdi, rdi
    syscall

e:
    mov rax, 60
    mov rdi, 1
    syscall

parse_int:
    xor r8, r8
    mov dl, [rsi]
    cmp dl, '-'
    jne .ps
    mov r8, 1
    inc rsi
.ps:
    xor rax, rax
.pi_loop:
    mov dl, [rsi]
    test dl, dl
    je .done
    sub dl, '0'
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .pi_loop
.done:
    test r8, r8
    jz .ret
    neg rax
.ret:
    ret

print_int:
    test rax, rax
    jns .pos
    mov byte [buffer], '-'
    neg rax
    lea rsi, [buffer+1]
    call convert_abs
    jmp .wr
.pos:
    lea rsi, [buffer]
    call convert_abs
.wr:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

convert_abs:
    mov rbx, rax
    cmp rbx, 0
    jne .loop
    mov byte [rsi], '0'
    mov rdx, 1
    ret
.loop:
    lea rdi, [rsi+31]
.cv:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .cv
    inc rdi
    mov rdx, rsi
    add rdx, 32
    sub rdx, rdi
    mov rsi, rdi
    ret
