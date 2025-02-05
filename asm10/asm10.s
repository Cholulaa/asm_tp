section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov r8, [rsp]
    cmp r8, 4
    jl e
    mov rsi, [rsp+16]
    call parse
    mov rbx, rax
    mov rsi, [rsp+24]
    call parse
    mov rcx, rax
    mov rsi, [rsp+32]
    call parse
    mov rdx, rax
    cmp rcx, rbx
    jle .c
    mov rbx, rcx
.c:
    cmp rdx, rbx
    jle .m
    mov rbx, rdx
.m:
    mov rax, rbx
    call print_signed
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
    jne d
    mov r8, 1
    inc rsi
d:
    xor rax, rax
l:
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
    jmp l
.done:
    test r8, r8
    jz r
    neg rax
r:
    ret

print_signed:
    test rax, rax
    jns .p
    mov byte [buffer], '-'
    neg rax
    lea rdi, [buffer+1]
    jmp c
.p:
    lea rdi, [buffer]
c:
    mov rcx, rax
    test rcx, rcx
    jnz .v
    mov byte [rdi], '0'
    inc rdi
    jmp w
.v:
    lea rsi, [buffer+63]
lp:
    xor rdx, rdx
    mov rax, rcx
    mov r8, 10
    div r8
    mov rcx, rax
    add rdx, '0'
    mov byte [rsi], dl
    dec rsi
    test rcx, rcx
    jnz lp
    inc rsi
    mov rax, buffer+64
    sub rax, rsi
cp:
    mov dl, [rsi]
    mov [rdi], dl
    inc rdi
    inc rsi
    dec rax
    jnz cp
w:
    mov rax, 1
    mov rsi, buffer
    sub rdi, buffer
    mov rdx, rdi
    mov rdi, 1
    syscall
    ret
