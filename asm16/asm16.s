; asm16 - Patcher for asm01: changes "1337" to "H4CK"
; Usage: ./asm16 asm01
; After patching, running ./asm01 will print "H4CK"

section .data
    search  db "1337"    ; 4-byte pattern to search for
    replace db "H4CK"    ; 4-byte replacement string

section .bss
    buffer  resb 1024    ; Buffer for reading the file

section .text
    global _start

_start:
    ; -------------------------------
    ; Check that a filename was provided.
    ; The argument count (argc) is stored at [rsp]
    ; and the first parameter (argv[1]) is at [rsp+16].
    ; -------------------------------
    mov r8, [rsp]          ; r8 = argc
    cmp r8, 2
    jl error               ; if less than 2, exit with error

    mov rdi, [rsp+16]      ; rdi = pointer to filename

    ; -------------------------------
    ; Open the file in read/write mode.
    ; Syscall: sys_open (number 2)
    ; -------------------------------
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR
    xor rdx, rdx           ; mode = 0 (not used)
    syscall
    test rax, rax
    js error               ; if negative return, error
    mov rbx, rax           ; save file descriptor in rbx

    ; -------------------------------
    ; Read up to 1024 bytes from the file.
    ; Syscall: sys_read (number 0)
    ; -------------------------------
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read
    mov rsi, buffer        ; read into buffer
    mov rdx, 1024          ; maximum bytes to read
    syscall
    test rax, rax
    jle close              ; if nothing was read, go to close
    mov rcx, rax           ; save number of bytes read in rcx

    ; -------------------------------
    ; Search for the 4-byte pattern "1337"
    ; in the buffer.
    ; -------------------------------
    mov rsi, buffer        ; start of buffer
    xor rdx, rdx           ; offset counter = 0

search_loop:
    cmp rdx, rcx           ; if reached end of read bytes...
    jge close              ; ...pattern not found, so exit with error

    mov eax, dword [search]  ; load "1337" into eax
    cmp dword [rsi], eax     ; compare 4 bytes at current position
    je replace_pattern       ; if equal, jump to replacement

    inc rsi                  ; move to next byte
    inc rdx                  ; update offset counter
    jmp search_loop

    ; -------------------------------
    ; Pattern found: replace "1337" with "H4CK"
    ; -------------------------------
replace_pattern:
    ; Seek to the found offset.
    ; Syscall: sys_lseek (number 8)
    mov rdi, rbx           ; file descriptor
    mov rax, 8             ; sys_lseek
    mov rsi, rdx           ; offset where the pattern was found
    xor rdx, rdx           ; SEEK_SET = 0
    syscall

    ; Write the replacement string.
    ; Syscall: sys_write (number 1)
    mov rdi, rbx           ; file descriptor
    mov rax, 1             ; sys_write
    mov rsi, replace       ; pointer to "H4CK"
    mov rdx, 4             ; write 4 bytes
    syscall

    ; -------------------------------
    ; Close the file and exit with code 0.
    ; -------------------------------
    mov rdi, rbx           ; file descriptor
    mov rax, 3             ; sys_close
    syscall

    xor rdi, rdi           ; exit code 0
    mov rax, 60            ; sys_exit
    syscall

    ; -------------------------------
    ; Error/close routines.
    ; -------------------------------
close:
    mov rdi, rbx           ; file descriptor
    mov rax, 3             ; sys_close
    syscall
error:
    mov rdi, 1             ; exit code 1 indicates error
    mov rax, 60            ; sys_exit
    syscall
