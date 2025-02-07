section .data
    elf_magic dd 0x464C457F      ; ELF magic number in little-endian
    expected dd 0x37333331      ; "1337" in little-endian
    replacement db "H4CK"       ; What we'll write instead

section .text
    global _start

_start:
    ; Check argc
    cmp qword [rsp], 2          ; Compare argc with 2
    jl .error                   ; Jump if less than 2 args

    ; Open file
    mov rdi, [rsp + 16]        ; argv[1] - filename
    mov rax, 2                 ; sys_open
    mov rsi, 2                 ; O_RDWR
    xor rdx, rdx              ; mode = 0
    syscall
    
    test rax, rax             ; Check for open error
    js .error
    mov rbx, rax              ; Save fd

    ; Read ELF header
    mov rdi, rax              ; fd
    xor rax, rax             ; sys_read
    mov rsi, buffer
    mov rdx, 4               ; Read 4 bytes
    syscall

    cmp rax, 4               ; Check bytes read
    jne .close_error

    ; Verify ELF magic
    mov eax, [buffer]
    cmp eax, [elf_magic]
    jne .close_error

    ; Seek to .data section (0x2000)
    mov rdi, rbx             ; fd
    mov rax, 8               ; sys_lseek
    mov rsi, 0x2000         ; offset
    xor rdx, rdx            ; SEEK_SET
    syscall

    cmp rax, 0x2000         ; Verify seek worked
    jne .close_error

    ; Read current content
    mov rdi, rbx
    xor rax, rax            ; sys_read
    mov rsi, buffer
    mov rdx, 4              ; Read 4 bytes
    syscall

    cmp rax, 4              ; Verify read
    jne .close_error

    ; Verify we found "1337"
    mov eax, [buffer]
    cmp eax, [expected]
    jne .close_error

    ; Seek back to write position
    mov rdi, rbx
    mov rax, 8              ; sys_lseek
    mov rsi, 0x2000        ; Same offset
    xor rdx, rdx           ; SEEK_SET
    syscall

    cmp rax, 0x2000        ; Verify seek
    jne .close_error

    ; Write "H4CK"
    mov rdi, rbx
    mov rax, 1             ; sys_write
    mov rsi, replacement
    mov rdx, 4            ; Write 4 bytes
    syscall

    cmp rax, 4            ; Verify write
    jne .close_error

    ; Close and exit successfully
    mov rdi, rbx
    mov rax, 3            ; sys_close
    syscall

    xor rdi, rdi          ; exit(0)
    mov rax, 60
    syscall

.close_error:
    mov rdi, rbx
    mov rax, 3            ; sys_close
    syscall

.error:
    mov rdi, 1            ; exit(1)
    mov rax, 60
    syscall

section .bss
    buffer resb 16        ; Buffer for reading