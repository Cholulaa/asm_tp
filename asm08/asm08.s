section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz err
    call parse
    test rax, rax
    jle zero
    cmp rax, 2
    jb zero
    mov rbx, rax
    dec rbx
    mul rbx
    xor rdx, rdx
    mov rcx, 2
    div rcx
zero:
    call print
    mov rax, 60
    xor rdi, rdi
    syscall
err:
    mov rax, 60
    mov rdi, 1
    syscall

parse:
    xor rax, rax
p_loop:
    mov dl, [rsi]
    test dl, dl
    jz done
    cmp dl, 10
    je done
    sub dl, '0'
    jl done
    cmp dl, 9
    jg done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp p_loop
done:
    ret

print:
    test rax, rax
    jnz p_conv
    mov byte [buffer], '0'
    mov rdx, 1
    jmp p_w
p_conv:
    mov rbx, rax
    lea rdi, [buffer+63]
p_loop2:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz p_loop2
    inc rdi
    mov rdx, buffer+64
    sub rdx, rdi
p_w:
    mov rax, 1
    mov rdi, 1
    mov rsi, rdi
    syscall
    ret
