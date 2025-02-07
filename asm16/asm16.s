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
    ; Check if we have an argument
    pop rcx         ; Get argc
    cmp rcx, 2
    jl .error
    
    ; Get the filename (skip argv[0])
    pop rcx         ; Skip program name
    pop rdi         ; Get filename (argv[1])
    
    ; Open file
    mov rax, SYS_open
    mov rsi, O_RDWR
    xor rdx, rdx
    syscall
    
    test rax, rax   ; Check for error
    js .error
    mov rbx, rax    ; Save file descriptor
    
    ; Read file
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 1024
    mov rax, SYS_read
    syscall
    
    test rax, rax   ; Check read success
    jle .close_error
    
    ; Search pattern
    mov rcx, rax     ; Save bytes read
    mov rsi, buffer
    xor rdx, rdx     ; Initialize offset counter
    
.search_loop:
    cmp rcx, 4       ; Need at least 4 bytes
    jl .close_error
    
    mov eax, dword [search]
    cmp dword [rsi], eax
    je .found
    
    inc rsi
    inc rdx
    dec rcx
    jmp .search_loop
    
.found:
    ; Seek to the position
    mov rdi, rbx     ; File descriptor
    mov rax, SYS_lseek
    mov rsi, rdx     ; Offset we calculated
    xor rdx, rdx     ; SEEK_SET
    syscall
    
    ; Write replacement
    mov rdi, rbx
    mov rsi, replace
    mov rdx, 4
    mov rax, SYS_write
    syscall
    
    ; Success path
    mov rdi, rbx
    mov rax, SYS_close
    syscall
    
    xor rdi, rdi     ; Exit code 0
    mov rax, SYS_exit
    syscall
    
.close_error:
    mov rdi, rbx
    mov rax, SYS_close
    syscall
    
.error:
    mov rax, SYS_exit
    mov rdi, 1       ; Exit code 1
    syscall

section .bss
    align 8
    buffer resb 1024