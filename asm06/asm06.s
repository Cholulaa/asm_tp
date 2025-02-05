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
    call parse
    mov rbx, rax
    mov rsi, rdi
    call parse
    add rax, rbx
    call printsigned
    mov rax, 60
    xor rdi, rdi
    syscall

e:
    mov rax, 60
    mov rdi, 1
    syscall

parse:
    xor r8, r8
    mov dl, [rsi]
    cmp dl, '-'
    jne s
    mov r8, 1
    inc rsi
s:
    xor rax, rax
pl:
    mov dl, [rsi]
    test dl, dl
    je ed
    sub dl, '0'
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp pl
ed:
    test r8, r8
    jz rt
    neg rax
rt:
    ret

printsigned:
    test rax, rax
    jns .pos
    mov byte [buffer], '-'
    neg rax
    lea rdi, [buffer+1]
    jmp .cv
.pos:
    lea rdi, [buffer]
.cv:
    mov rcx, rax
    cmp rcx, 0
    jne .lp
    mov byte [rdi], '0'
    mov rdx, 1
    jmp .wr
.lp:
    lea rsi, [rdi+63]
.n:
    xor rdx, rdx
    mov rax, rcx
    mov r8, 10
    div r8
    mov rcx, rax
    add rdx, '0'
    mov byte [rsi], dl
    dec rsi
    test rcx, rcx
    jnz .n
    inc rsi
    mov rdx, rdi
    add rdx, 64
    sub rdx, rsi
    mov rdi, rsi
.wr:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret
