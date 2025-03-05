section .data

section .bss
    buffer resb 1024

section .text
    global _start

_start:
    cmp qword [rsp], 2
    jl error

    mov rsi, [rsp+16]
    xor rax, rax
.convert_loop:
    movzx rcx, byte [rsi]
    test rcx, rcx
    je .convert_done
    cmp cl, 10
    je .convert_done
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    inc rsi
    jmp .convert_loop
.convert_done:
    xor rdx, rdx
    mov rcx, 26
    div rcx
    mov r13, rdx

    mov rdi, 0
    mov rax, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall
    mov r12, rax
    mov rcx, rax
    mov rsi, buffer

.process_loop:
    test rcx, rcx
    je .write_output
    mov al, byte [rsi]
    cmp al, 'a'
    jl .check_upper
    cmp al, 'z'
    jg .check_upper
    add al, r13b
    cmp al, 'z'
    jle .store
    sub al, 26
    jmp .store
.check_upper:
    cmp al, 'A'
    jl .store
    cmp al, 'Z'
    jg .store
    add al, r13b
    cmp al, 'Z'
    jle .store
    sub al, 26
.store:
    mov byte [rsi], al
    inc rsi
    dec rcx
    jmp .process_loop

.write_output:
    mov rdi, 1
    mov rax, 1
    mov rsi, buffer
    mov rdx, r12
    syscall
    xor rdi, rdi
    mov rax, 60
    syscall

error:
    mov rdi, 1
    mov rax, 60
    syscall
 