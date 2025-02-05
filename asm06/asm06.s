section .data
buffer: times 32 db 0

section .text
global _start

_start:
    mov rsi, [rsp+16]
    test rsi, rsi
    jz exit_error
    mov rdi, [rsp+24]
    test rdi, rdi
    jz exit_error
    call parse_int
    mov rbx, rax
    mov rsi, rdi
    call parse_int
    add rax, rbx
    call print_int
    mov rax, 60
    xor rdi, rdi
    syscall

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

parse_int:
    xor rax, rax
    xor rcx, rcx
.parse_loop:
    mov cl, [rsi]
    test cl, cl
    je .done
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    inc rsi
    jmp .parse_loop
.done:
    ret

print_int:
    mov rbx, rax
    cmp rbx, 0
    jne .convert
    mov byte [buffer], '0'
    mov rdx, 1
    jmp .write_out
.convert:
    mov rdi, buffer
    add rdi, 31
    xor rcx, rcx
.convert_loop:
    xor rdx, rdx
    mov rax, rbx
    mov r8, 10
    div r8
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .convert_loop
    add rdi, 1
    mov rsi, rdi
    mov rdx, buffer+32
    sub rdx, rdi
.write_out:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
