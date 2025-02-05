section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz e
    call parse
    cmp rax, 2
    jb z
    mov rbx, rax
    dec rbx
    mul rbx
    xor rdx, rdx
    mov rcx, 2
    div rcx
z:
    call print
    mov rax, 60
    xor rdi, rdi
    syscall
e:
    mov rax, 60
    mov rdi, 1
    syscall

parse:
    xor rax, rax
pl:
    mov dl, [rsi]
    test dl, dl
    jz d
    cmp dl, 10
    je d
    sub dl, '0'
    jl d
    cmp dl, 9
    jg d
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp pl
d:
    ret

print:
    test rax, rax
    jnz cv
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp w
cv:
    mov rbx, rax
    lea rdi, [buffer+63]
lp:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz lp
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
w:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
