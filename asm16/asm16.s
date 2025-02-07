section .data
    search db "1337"   ; String to search
    replace db "H4CK"  ; Replacement string
    
section .text
    global _start
%define SYS_open 2
%define SYS_read 0
%define SYS_write 1
%define SYS_lseek 8
%define SYS_close 3
%define SYS_exit 60
%define O_RDWR 2

_start:
    ; Check command line arguments
    pop rax         ; Get argc
    cmp rax, 2
    jl .error
    
    ; Open the file
    pop rax         ; Discard program name
    pop rdi         ; Get filename argument
    mov rax, SYS_open
    mov rsi, O_RDWR
    xor rdx, rdx
    syscall
    
    cmp rax, 0
    jl .error
    mov rbx, rax    ; Save file descriptor
    
    ; Read file content
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 1024
    mov rax, SYS_read
    syscall
    
    cmp rax, 0
    jle .close_error
    
    ; Search and replace
    mov rcx, rax    ; Store bytes read
    mov rsi, buffer
.find_loop:
    cmp rcx, 4
    jl .close_error
    
    mov eax, dword [rsi]
    cmp eax, dword [search]
    je .found
    
    inc rsi
    dec rcx
    jmp .find_loop
    
.found:
    ; Seek to position
    mov rdi, rbx
    mov rax, SYS_lseek
    mov rdx, 0      ; SEEK_SET
    mov rsi, rsi
    sub rsi, buffer ; Calculate offset
    syscall
    
    ; Write replacement
    mov rdi, rbx
    mov rsi, replace
    mov rdx, 4
    mov rax, SYS_write
    syscall
    
    ; Close and exit
    mov rdi, rbx
    mov rax, SYS_close
    syscall
    
    xor rdi, rdi
    mov rax, SYS_exit
    syscall
    
.close_error:
    mov rdi, rbx
    mov rax, SYS_close
    syscall
    
.error:
    mov rdi, 1
    mov rax, SYS_exit
    syscall

section .bss
    align 8
    buffer resb 1024