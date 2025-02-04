section .bss
    number resb 10  

section .text
    global _start

_start:
    mov rax, 0          
    mov rdi, 0          
    mov rsi, number     
    mov rdx, 10         
    syscall

    mov rsi, number
    call str_to_int

    test rax, 1          
    jz return_zero       

return_one:
    mov rax, 60         
    mov rdi, 1          
    syscall

return_zero:
    mov rax, 60         
    mov rdi, 0          
    syscall

str_to_int:
    xor rax, rax        
    xor rcx, rcx        

.loop:
    movzx rdx, byte [rsi]  
    cmp rdx, 10        
    je .done
    sub rdx, '0'       
    imul rax, rax, 10  
    add rax, rdx       
    inc rsi            
    jmp .loop

.done:
    ret
