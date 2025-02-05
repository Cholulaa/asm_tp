section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov r8, [rsp]         ; argc
    cmp r8, 3
    jl error              ; need at least 3 params => argv[1], argv[2], argv[3]

    ; Parse argv[1] => RBX
    mov rsi, [rsp+16]
    call parse
    mov rbx, rax

    ; Parse argv[2] => RCX
    mov rsi, [rsp+24]
    call parse
    mov rcx, rax

    ; Parse argv[3] => RDX
    mov rsi, [rsp+32]
    call parse
    mov rdx, rax

    ; Find max among rbx, rcx, rdx => store in rbx
    cmp rcx, rbx
    jle .check3
    mov rbx, rcx
.check3:
    cmp rdx, rbx
    jle .print
    mov rbx, rdx

.print:
    mov rax, rbx
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

; ------------------------------------------------------------
; parse: Parse a non-negative decimal from RSI => RAX
; ------------------------------------------------------------
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

; ------------------------------------------------------------
; print: Print the unsigned integer in RAX (decimal) => stdout
; ------------------------------------------------------------
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
