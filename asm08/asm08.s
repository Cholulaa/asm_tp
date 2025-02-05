section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz error
    call parse
    cmp rax, 2
    jb .zero
    mov rbx, rax
    dec rbx
    mul rbx
    xor rdx, rdx
    mov rcx, 2
    div rcx
    jmp .print

.zero:
    xor rax, rax

.print:
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

parse:
    xor rax, rax
.parse_loop:
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
    jmp .parse_loop
.done:
    ret

print:
    test rax, rax
    jnz .convert
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp .write

.convert:
    mov rbx, rax
    lea rdi, [buffer+63]
.conv_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .conv_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
.write:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
