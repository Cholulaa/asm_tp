section .data
buffer: times 64 db 0

section .text
global _start

_start:
    xor rax, rax
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 64
    syscall
    mov rcx, rax
    xor rbx, rbx
loop_read:
    test rcx, rcx
    jz done
    mov al, [rsi]
    inc rsi
    dec rcx
    call is_vowel
    add rbx, rax
    jmp loop_read
done:
    mov rax, rbx
    call print_dec
    mov rax, 60
    xor rdi, rdi
    syscall

is_vowel:
    cmp al, 'a'
    je ret1
    cmp al, 'e'
    je ret1
    cmp al, 'i'
    je ret1
    cmp al, 'o'
    je ret1
    cmp al, 'u'
    je ret1
    cmp al, 'y'
    je ret1
    cmp al, 'A'
    je ret1
    cmp al, 'E'
    je ret1
    cmp al, 'I'
    je ret1
    cmp al, 'O'
    je ret1
    cmp al, 'U'
    je ret1
    cmp al, 'Y'
    je ret1
    xor rax, rax
    ret
ret1:
    mov rax, 1
    ret

print_dec:
    test rax, rax
    jnz conv
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp wr
conv:
    mov rbx, rax
    lea rdi, [buffer+63]
c_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz c_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
wr:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
 