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
    
    mov r13, [rsp]  ; is there the attended arguments ?
    cmp r13, 3
    jne _error

    mov rsi, rsp
    add rsi, 16
    mov rsi, [rsi]
    mov rdi, nb1    ; keeping first number
    mov rcx, 4
    rep movsb

    mov rsi, rsp
    add rsi, 24
    mov rsi, [rsi]
    mov rdi, nb2    ; keeping second number
    mov rcx, 4
    rep movsb

    mov byte [signNb1], 0   ; we initalize the sign at positiv
    mov byte [signNb2], 0   ; it will change later if its negativ
    mov byte [finalSign], 0


    xor rdi, rdi
    mov r8, 0

sign1:                      ; change the value of sign1 var if the number1 is negativ
    mov al, [nb1 + rdi]
    cmp al, '-'             ; we check if the first char is a '-', meaning the number1 is negativ
    je ._negativ
    jne convert1            ; otherwise we can convert the first number
    ._negativ:    
        mov byte [signNb1], 1
        inc rdi
        jmp convert1
    
convert1: 
    mov al, [nb1 + rdi]
    cmp al, 0
    je done1

    cmp rax, '0'    ; we check if its a number or not, which means between char 0 (48) and char 9 (57)

    jl _error

    cmp rax, '9'
    jg _error

    sub rax, 48     ; we sub the value for char 0 (48) to get its decimal form
    imul r8, 10 ; imul to write number from left to right 
    add r8, rax

    inc rdi
    jmp convert1

done1:
    xor rdi, rdi
    mov r9, 0

sign2:              ; same as sign1 but for number2
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

    mov al, [signNb1]   ; we compare both sign of each number
    mov bl, [signNb2]   ; it will change all the calcul process
    cmp al, bl
    je ._sameSign
    jne ._diffSign

    ._sameSign:         ; if signs are the same, we just add numbers and set the finalSign as negativ (1)
        cmp al, 0
        jne ._neg
        add r9, r8
        jmp _end ; both positiv we can already exit 
        ._neg:
            mov byte [finalSign], 1
            add r9, r8 ; both negativ we can exit with finalSign swapped to 1
            jmp _end
    ._diffSign:       ; if signs are different, we substract the biggest of the 2 numbers and then set the finalSign as the biggest number (1 for negativ, 0 for positiv)
        cmp r8, r9
        ja ._nb1Greater
        jb ._nb2Greater
        mov r9, 0 ; if nb 1 = nb 2, result is 0 we dont even need to add
        jmp _end
        ._nb1Greater:
            sub r8, r9
            mov r9, r8
            mov al, [signNb1] ; cause nb1 is bigger, the result will be its sign
            mov [finalSign], al
            jmp _end
        ._nb2Greater:
            sub r9, r8
            mov al, [signNb2] ; cause nb2 is bigger, the result will be its sign
            mov [finalSign], al
            jmp _end



_end:
    mov rax, r9
    mov rcx, [finalSign]
    call std__to_string   ; we call our convert/print function

_exit:
    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall


_error:

    mov rax, 1    ; print help message if there is an error
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
    ; ----------------------------------------------------------------------
    ;    TAKES
    ;        ||------> 1. RAX => Number
    ;                  2. RSI => Output string
    ;                  3. RCX => finalSign (0 or 1)
    ;
    ;    GIVES
    ;        ||------> 1. RSI = Number as a string
    ;                  2. RDX = Length of the string (number of digits)
    ;
    ; ----------------------------------------------------------------------

    push rsi              ; Keep the output string pointer on the stack for later
    push rax              ; Keep the value of RAX on the stack because the next loop will change its value

    cmp rcx, 1            ; Check if finalSign is 1
    jne .no_sign          ; If not, jump to .no_sign

    mov byte [rsi], '-'   ; Add '-' at the beginning of the string
    inc rsi               ; Increment the string pointer
    mov rdi, 2            ; Set the initial number of digits to 2 to account for the negative sign

    jmp .continue         ; Jump to the main loop

.no_sign:
    mov rdi, 1            ; Set the initial number of digits to 1 (no negative sign)

.continue:
    mov rcx, 1            ; For keeping the divisor
    mov rbx, 10           ; For dividing the number by ten in each iteration 
    .get_divisor:
        xor rdx, rdx
        div rbx           ; Reduce the RAX by one digit
        
        cmp rax, 0        ; Compare RAX with zero
        je ._after         ; Break the loop if equal
        imul rcx, 10      ; Otherwise increase the divisor (RCX) ten times
        inc rdi           ; Increment number of digits as well (RDI)
        jmp .get_divisor   ; Unconditional jump to the first instruction of the 'loop'

    ._after:
        pop rax           ; Get back the value of RAX from the stack
        push rdi          ; Put the number of digits on the stack for later

    .to_string:
        xor rdx, rdx
        div rcx           ; Divide the number (RAX) by the divisor to get the first digit from the left

        add al, '0'       ; Add the base (48) to the digit because we want to store an ASCII string
        mov [rsi], al     ; Move the value into the string
        inc rsi           ; Increment the pointer to the next byte

        push rdx          ; Push the remaining part of the number onto the stack
        xor rdx, rdx      
        mov rax, rcx     
        mov rbx, 10       
        div rbx           ; Reduce the divisor (RCX) ten times
        mov rcx, rax      ; Put the new divisor back into (RCX)

        pop rax           ; Pop the top the stack into (RAX). It's the remaining part of the number
        
        cmp rcx, 0        ; See if the divisor has become zero
        jg .to_string      ; If not, repeat the same process
    
    mov byte [rsi + rdx], 0
    pop rdx               ; Pop the top of the stack into (RDX). It's the value of (RDI): the number of digits in the original number
    pop rsi               ; Bring (RSI) to the beginning of the string before returning as well
    ret

