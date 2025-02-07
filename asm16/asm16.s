section .data
    search db "1337"
    replace db "H4CK"

section .text
    global _start

_start:
    ; Check argc (number of arguments)
    mov rdi, [rsp]      ; Get argc
    cmp rdi, 2          ; Need at least 2 (program name + 1 argument)
    jl .error

    ; Get argv[1] - filename
    mov rdi, [rsp + 16] ; Get pointer to filename

    ; Open file
    mov rax, 2          ; sys_open
    mov rsi, 2          ; O_RDWR
    xor rdx, rdx        ; mode
    syscall

    ; Check if open succeeded
    test rax, rax
    js .error
    mov rbx, rax        ; Save fd

    ; Read file content
    mov rdi, rbx        ; fd
    mov rax, 0          ; sys_read
    mov rsi, buffer     ; buffer
    mov rdx, 1024       ; count
    syscall

    ; Check read success
    test rax, rax
    jle .close

    ; Search for pattern
    mov rsi, buffer     ; Source
    xor rdx, rdx        ; Offset counter

.loop:
    mov eax, [search]   ; Load search pattern
    cmp [rsi], eax      ; Compare with current position
    je .replace         ; Found it!

    inc rsi             ; Next position
    inc rdx             ; Increment offset
    cmp rdx, rax        ; Check if we reached end
    jl .loop
    jmp .close          ; Pattern not found

.replace:
    ; Seek to position
    mov rdi, rbx        ; fd
    mov rax, 8          ; sys_lseek
    mov rsi, rdx        ; offset
    xor rdx, rdx        ; SEEK_SET
    syscall

    ; Write replacement
    mov rdi, rbx        ; fd
    mov rax, 1          ; sys_write
    mov rsi, replace    ; buffer
    mov rdx, 4          ; count
    syscall

    ; Close file and exit successfully
    mov rdi, rbx
    mov rax, 3          ; sys_close
    syscall
    
    xor rdi, rdi        ; Success exit code
    mov rax, 60         ; sys_exit
    syscall

.close:
    mov rdi, rbx
    mov rax, 3          ; sys_close
    syscall

.error:
    mov rdi, 1          ; Error exit code
    mov rax, 60         ; sys_exit
    syscall

section .bss
    buffer resb 1024