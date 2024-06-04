global _start

section .bss
    nb1 resb 32
    nb2 resb 32
    signNb1 resb 1 
    signNb2 resb 1
    finalSign resb 1

section .data
    help: db "Add 2 numbers sent in parameter, accepts negativ numbers", 10
    .lenHelp: equ $ - help
    usage: db "USAGE : ./asm08 NUMBER1 NUMBER2", 10
    .lenUsage: equ $ - usage

section .text
_start:
    mov r13, [rsp]
    cmp r13, 3
    jne _error

    mov rsi, rsp
    add rsi, 16
    mov rsi, [rsi]
    mov rdi, nb1
    mov rcx, 4
    rep movsb

    mov rsi, rsp
    add rsi, 24
    mov rsi, [rsi]
    mov rdi, nb2
    mov rcx, 4
    rep movsb

    mov byte [signNb1], 0
    mov byte [signNb2], 0
    mov byte [finalSign], 0

    xor rdi, rdi
    mov r8, 0

sign1:
    mov al, [nb1 + rdi]
    cmp al, '-'
    je ._negativ
    jne convert1
    ._negativ:
        mov byte [signNb1], 1
        inc rdi
        jmp convert1

convert1:
    mov al, [nb1 + rdi]
    cmp al, 0
    je done1

    cmp rax, '0'
    jl _error

    cmp rax, '9'
    jg _error

    sub rax, 48
    imul r8, 10
    add r8, rax

    inc rdi
    jmp convert1

done1:
    xor rdi, rdi
    mov r9, 0

sign2:
    mov al, [nb2]
    cmp al, '-'
    je ._negativ
    jne convert2
    ._negativ:
        inc rdi
        mov byte [signNb2], 1
        jmp convert2

convert2:
    mov al, [nb2 + rdi]
    cmp rax, 0
    je done2

    cmp rax, '0'
    jl _error

    cmp rax, '9'
    jg _error

    sub rax, 48
    imul r9, 10
    add r9, rax

    inc rdi
    jmp convert2

done2:
    mov al, [signNb1]
    mov bl, [signNb2]
    cmp al, bl
    je ._sameSign
    jne ._diffSign

    ._sameSign:
        cmp al, 0
        jne ._neg
        add r9, r8
        jmp _end
        ._neg:
            mov byte [finalSign], 1
            add r9, r8
            jmp _end
    ._diffSign:
        cmp r8, r9
        ja ._nb1Greater
        jb ._nb2Greater
        mov r9, 0
        jmp _end
        ._nb1Greater:
            sub r8, r9
            mov r9, r8
            mov al, [signNb1]
            mov [finalSign], al
            jmp _end
        ._nb2Greater:
            sub r9, r8
            mov al, [signNb2]
            mov [finalSign], al
            jmp _end

_end:
    mov rax, r9
    mov rcx, [finalSign]
    call std__to_string

_exit:
    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, help
    mov rdx, help.lenHelp
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, usage
    mov rdx, usage.lenUsage
    syscall

    mov rax, 60
    mov rdi, 1  
    syscall

std__to_string:
    push rsi
    push rax
    cmp rcx, 1
    jne .no_sign
    mov byte [rsi], '-'
    inc rsi
    mov rdi, 2
    jmp .continue

.no_sign:
    mov rdi, 1

.continue:
    mov rcx, 1
    mov rbx, 10
    .get_divisor:
        xor rdx, rdx
        div rbx
        cmp rax, 0
        je ._after
        imul rcx, 10
        inc rdi
        jmp .get_divisor

    ._after:
        pop rax
        push rdi

    .to_string:
        xor rdx, rdx
        div rcx
        add al, '0'
        mov [rsi], al
        inc rsi
        push rdx
        xor rdx, rdx
        mov rax, rcx
        mov rbx, 10
        div rbx
        mov rcx, rax
        pop rax
        cmp rcx, 0
        jg .to_string
    
    mov byte [rsi + rdx], 0
    pop rdx
    pop rsi
    ret
