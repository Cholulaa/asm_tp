section .text
    global _start

_start:
    mov rsi, [rsp+16]  
    test rsi, rsi      
    jz exit_error      

    call string_length 

    mov rax, 1        
    mov rdi, 1        
    syscall

exit_success:
    mov rax, 60       
    xor rdi, rdi      
    syscall

exit_error:
    mov rax, 60       
    mov rdi, 1        
    syscall

string_length:
    xor rdx, rdx      
.loop:
    cmp byte [rsi+rdx], 0 
    je .done
    inc rdx           
    jmp .loop
.done:
    ret
