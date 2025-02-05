section .data
buffer: times 64 db 0

section .text
global _start

_start:
    mov r8, [rsp]        ; argc
    cmp r8, 4            ; need 3 user-supplied params => argc >= 4
    jl e

    ; argv[1]
    mov rsi, [rsp+16]
    call parse
    mov rbx, rax

    ; argv[2]
    mov rsi, [rsp+24]
    call parse
    mov rcx, rax

    ; argv[3]
    mov rsi, [rsp+32]
    call parse
    mov rdx, rax

    ; find max of (rbx, rcx, rdx)
    cmp rcx, rbx
    jle .check3
    mov rbx, rcx
.check3:
    cmp rdx, rbx
    jle .p
    mov rbx, rdx
.p:
    mov rax, rbx
    call print_signed
    mov rax, 60
    xor rdi, rdi
    syscall

e:
    mov rax, 60
    mov rdi, 1
    syscall

; parse signed integer in ASCII
; RSI => pointer, RAX => result
parse:
    xor r8, r8
    mov dl, [rsi]
    cmp dl, '-'
    jne .digits
    mov r8, 1
    inc rsi
.digits:
    xor rax, rax
.loop:
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
    jmp .loop
.done:
    test r8, r8
    jz .ret
    neg rax
.ret:
    ret

; print_signed RAX => print decimal (with '-' if negative)
print_signed:
    test rax, rax
    jns .pos
    mov byte [buffer], '-'
    neg rax
    lea rdi, [buffer+1]
    jmp .conv
.pos:
    lea rdi, [buffer]
.conv:
    mov rbx, rax
    cmp rbx, 0
    jne .conv_loop
    mov byte [rdi], '0'
    inc rdi
    jmp .finish
.conv_loop:
    lea rsi, [rdi+63]
.print_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rsi], dl
    dec rsi
    test rbx, rbx
    jnz .print_loop
    inc rsi
    mov rdx, rdi
    add rdx, 64
    sub rdx, rsi
    mov rax, rsi
    mov rsi, rdi
    rep movsb
.finish:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    sub rdi, rdi  ; not actually needed, but no harm
    ; fix length
    ; we can compute the length easily; let's do a simpler approach:
    ; We'll do what's simplest: after building the number, rdi points
    ; after digits or minus sign. Let's do a small approach:

    ; Actually let's do a simpler approach:
    ; We'll store everything in the buffer from the end, then
    ; copy it down. The code above does that.

    syscall
    ret
