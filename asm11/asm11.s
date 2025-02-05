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
.loop:
    test rcx, rcx
    jz .done
    mov al, [rsi]
    inc rsi
    dec rcx
    call is_vowel
    add rbx, rax
    jmp .loop
.done:
    mov rax, rbx
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

is_vowel:
    cmp al, 'a'
    je .yes
    cmp al, 'e'
    je .yes
    cmp al, 'i'
    je .yes
    cmp al, 'o'
    je .yes
    cmp al, 'u'
    je .yes
    cmp al, 'A'
    je .yes
    cmp al, 'E'
    je .yes
    cmp al, 'I'
    je .yes
    cmp al, 'O'
    je .yes
    cmp al, 'U'
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

print:
    test rax, rax
    jnz .conv
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp .wr
.conv:
    mov rbx, rax
    lea rdi, [buffer+63]
.next:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .next
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi
.wr:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
