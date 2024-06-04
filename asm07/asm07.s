global _start 

section .bss
    nb resb 32

section .data
    help: db "Add numbers from 0 to NUMBER-1", 10
    .lenHelp: equ $ - help
    usage: db "USAGE : ./asm07 NUMBER", 10
    .lenUsage: equ $ - usage

section .text
_start:

    mov r13, [rsp]
    cmp r13, 0x2
    jne _error

    mov rsi, rsp
    add rsi, 16
    mov rsi, [rsi]
    mov rdi, nb
    mov rcx, 4
    rep movsb

    xor rdi, rdi
    mov r8, 0

convert:
    mov al, [nb + rdi]
    cmp al, 0
    je done

    cmp rax, '0'
    jl _error

    cmp rax, '9'
    jg _error

    sub rax, 48
    imul r8, 10
    add r8, rax
    
    inc rdi
    jmp convert

done:
    cmp r8, 0
    je _end
    
    mov r9, 0
    mov rax, 0
    dec r8

loop:
    add rax, r9
    
    cmp r9, r8
    je _end

    inc r9
    jmp loop

_end:
    call std__to_string
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

    mov rdi, 1
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

    pop rdx
    pop rsi
    ret
