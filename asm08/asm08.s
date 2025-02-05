section .data
buffer: times 64 db 0

section .text
global _start

; asm08 : somme des entiers < n
; Exemples:
;  ./asm08 5   => 1+2+3+4 = 10
;  ./asm08 10  => 1..9 => 45
;  ./asm08 1   => 0
;  ./asm08 0   => 0

_start:
    mov rsi, [rsp+16]    ; pointer to argv[1]
    test rsi, rsi
    jz error             ; if no param => exit(1)

    call parse           ; RAX = parsed integer
    test rax, rax
    jle zero             ; if <= 0 => sum = 0
    cmp rax, 2
    jb zero              ; if 1 => sum = 0

    ; sum(1..(n-1)) = n*(n-1)/2
    ; RAX = n
    mov rbx, rax
    dec rbx              ; RBX = n-1
    mul rbx              ; RDX:RAX = n*(n-1)
    xor rdx, rdx
    mov rcx, 2
    div rcx              ; RAX = (n*(n-1))/2

zero:
    call print
    mov rax, 60
    xor rdi, rdi         ; exit(0)
    syscall

error:
    mov rax, 60
    mov rdi, 1           ; exit(1)
    syscall

; ------------------------------------------------------------------------------
; parse:
;   RSI points to a C-string with the ASCII decimal number
;   Return value in RAX (>= 0).
;   Stops on end of string or newline. Anything non-digit ends parsing.
; ------------------------------------------------------------------------------
parse:
    xor rax, rax
.p_loop:
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
    jmp .p_loop
.done:
    ret

; ------------------------------------------------------------------------------
; print:
;   Prints RAX as a decimal number to stdout
; ------------------------------------------------------------------------------
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
.convert_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx             ; RAX=quotient, RDX=remainder
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .convert_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi

.write:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
