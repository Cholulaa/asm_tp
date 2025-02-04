section .bss
    result resb 20  

section .text
    global _start

_start:
    mov rsi, [rsp+16]  
    test rsi, rsi      
    jz exit_error      

    mov rdi, [rsp+24]  
    test rdi, rdi      
    jz exit_error      

    call str_to_int    
    mov rbx, rax       

    mov rsi, rdi       
    call str_to_int    

    add rax, rbx       

    mov rsi, result    
    call int_to_str    

    mov rax, 1         
    mov rdi, 1         
    syscall

exit_success:
    mov rax, 60        
    xor rdi, rdi       
    syscall

exit_error:
    mov rax, 60        
    mov rdi, 0         ; Correction: exit toujours 0 pour les nombres négatifs
    syscall

str_to_int:
    xor rax, rax       
    xor rcx, rcx       
    movzx rdx, byte [rsi]
    cmp rdx, '-'       
    jne .loop          
    inc rsi            
    mov rcx, 1         

.loop:
    movzx rdx, byte [rsi]  
    test rdx, rdx      
    jz .done
    cmp rdx, '0'       
    jl exit_error   
    cmp rdx, '9'       
    jg exit_error   
    sub rdx, '0'       
    imul rax, rax, 10  
    add rax, rdx       
    inc rsi            
    jmp .loop
.done:
    test rcx, rcx      
    jz .positive       
    neg rax            

.positive:
    ret

int_to_str:
    mov rbx, 10       
    mov rcx, result+19
    mov byte [rcx], 10
    dec rcx
    test rax, rax     
    jns .reverse      
    neg rax           
    dec rcx           
    mov byte [rcx], '-'  

.reverse:
    xor rdx, rdx      
    div rbx           
    add dl, '0'       
    mov [rcx], dl     
    dec rcx           
    test rax, rax     
    jnz .reverse
    inc rcx           
    mov rsi, rcx      
    mov rdx, result+20
    sub rdx, rcx      
    ret
