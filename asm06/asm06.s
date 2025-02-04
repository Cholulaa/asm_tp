section .bss
    result resb 20  

section .text
    global _start

_start:
    mov rdi, [rsp]      ; Get the number of arguments
    cmp rdi, 3          ; Check if there are exactly 2 arguments (program name + 2 args)
    jl exit_error       ; If not, exit with an error

    mov rsi, [rsp+16]   ; Get the first argument (argv[1])
    mov rdi, [rsp+24]   ; Get the second argument (argv[2])

    call str_to_int     ; Convert the first argument to an integer
    mov rbx, rax        ; Store the result in rbx

    mov rsi, rdi        ; Move the second argument to rsi
    call str_to_int     ; Convert the second argument to an integer

    add rax, rbx        ; Add the two integers

    mov rsi, result     ; Point rsi to the result buffer
    call int_to_str     ; Convert the result to a string

    ; Print the result
    mov rax, 1          ; syscall: write
    mov rdi, 1          ; file descriptor: stdout
    mov rsi, result     ; buffer to write
    mov rdx, 20         ; maximum length
    syscall

exit_success:
    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; exit code: 0
    syscall

exit_error:
    mov rax, 60         ; syscall: exit
    mov rdi, 1          ; exit code: 1
    syscall

str_to_int:
    xor rax, rax        ; Clear rax (result)
    xor rcx, rcx        ; Clear rcx (negative flag)
    movzx rdx, byte [rsi] ; Load the first character
    cmp rdx, '-'        ; Check if the number is negative
    jne .loop           ; If not, proceed to the loop
    inc rsi             ; Skip the '-' character
    mov rcx, 1          ; Set the negative flag

.loop:
    movzx rdx, byte [rsi] ; Load the next character
    test rdx, rdx       ; Check for null terminator
    jz .done
    cmp rdx, '0'        ; Check if the character is a digit
    jl exit_error       ; If not, exit with an error
    cmp rdx, '9'        ; Check if the character is a digit
    jg exit_error       ; If not, exit with an error
    sub rdx, '0'        ; Convert the character to a digit
    imul rax, rax, 10   ; Multiply the result by 10
    add rax, rdx        ; Add the digit to the result
    inc rsi             ; Move to the next character
    jmp .loop

.done:
    test rcx, rcx       ; Check if the number is negative
    jz .positive        ; If not, return the result
    neg rax             ; Negate the result

.positive:
    ret

int_to_str:
    mov rbx, 10         ; Base 10
    mov rcx, result+19  ; Point to the end of the buffer
    mov byte [rcx], 10  ; Add a newline character
    dec rcx             ; Move back one position
    test rax, rax       ; Check if the number is negative
    jns .reverse        ; If not, proceed to reverse
    neg rax             ; Negate the number
    dec rcx             ; Move back one position
    mov byte [rcx], '-' ; Add a '-' character

.reverse:
    xor rdx, rdx        ; Clear rdx
    div rbx             ; Divide rax by 10
    add dl, '0'         ; Convert the remainder to a character
    mov [rcx], dl       ; Store the character
    dec rcx             ; Move back one position
    test rax, rax       ; Check if there are more digits
    jnz .reverse        ; If so, repeat
    inc rcx             ; Move to the start of the string
    mov rsi, rcx        ; Point rsi to the start of the string
    mov rdx, result+20  ; Calculate the length of the string
    sub rdx, rcx        ; Subtract the start position
    ret