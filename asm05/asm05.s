section .text
    global _start

_start:
    mov rsi, [rsp+8]  
    test rsi, rsi     
    jz exit           

    call string_length 

    mov rax, 1        
    mov rdi, 1        
    syscall

exit:
    mov rax, 60       
    xor rdi, rdi      
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
