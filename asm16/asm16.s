; asm16 - Advanced patcher for asm01
; Goal: Patch the asm01 binary (passed as parameter) so that it displays "H4CK" instead of "1337"
;
; Usage:
;    ./asm16 asm01
; After patching, running:
;    ./asm01
; will display:
;    H4CK
;
; Enhancements added:
;  1. Verify that the file is an ELF file (check ELF magic in the header).
;  2. Scan the first 1024 bytes for all occurrences of "1337" and patch them.
;  3. If no "1337" is found, check if the file is already patched ("H4CK").
;  4. More robust error handling.

section .data
    search  db "1337"        ; 4-byte pattern to search for.
    replace db "H4CK"        ; 4-byte replacement string.
    elf_magic dd 0x464C457F    ; ELF magic number: 0x7F 'E' 'L' 'F' (in little-endian).

section .bss
    buffer  resb 1024        ; Buffer to read up to 1024 bytes of the file.

section .text
    global _start

_start:
    ; -----------------------------------------------------
    ; 1. Check for at least one parameter.
    ;    [rsp] = argc, [rsp+16] = argv[1] (filename)
    mov rdi, [rsp]         ; rdi = argc
    cmp rdi, 2             ; require at least 2 arguments
    jl exit_error

    ; -----------------------------------------------------
    ; 2. Get the filename from argv[1].
    mov rdi, [rsp+16]      ; rdi -> filename

    ; -----------------------------------------------------
    ; 3. Open the file in read/write mode.
    mov rax, 2             ; sys_open = 2
    mov rsi, 2             ; flags: O_RDWR
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error          ; if negative, error
    mov rbx, rax           ; save file descriptor in rbx

    ; -----------------------------------------------------
    ; 4. Read up to 1024 bytes from the file.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read = 0
    mov rsi, buffer        ; destination buffer
    mov rdx, 1024          ; number of bytes to read
    syscall
    test rax, rax
    jle close_fd_error     ; nothing read or error
    mov rcx, rax           ; rcx = number of bytes read

    ; -----------------------------------------------------
    ; 5. Verify the file appears to be an ELF binary.
    cmp rcx, 4             ; need at least 4 bytes to check header
    jl close_fd_error
    mov eax, dword [buffer]
    cmp eax, elf_magic
    jne close_fd_error     ; not an ELF? then error.

    ; -----------------------------------------------------
    ; 6. Search for the pattern "1337" in the buffer.
    ;    (We will patch every occurrence found.)
    mov rsi, buffer        ; rsi points to start of buffer
    xor rdx, rdx           ; rdx = offset into buffer
    xor r9, r9             ; r9 will be used as a "patched" flag (0 = not patched)

search_loop:
    ; Check that at least 4 bytes remain.
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl finish_search       ; not enough bytes left to compare

    mov eax, dword [search]    ; load "1337"
    cmp dword [rsi], eax       ; compare 4 bytes at [rsi]
    je do_patch

    inc rsi                    ; advance pointer by one byte
    inc rdx                    ; increment offset counter
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

do_patch:
    ; Set patched flag to 1.
    mov r9, 1
    ; -----------------------------------------------------
    ; 7. Patch the occurrence.
    ;     Seek to the found offset in the file.
    mov rdi, rbx          ; file descriptor remains in rbx
    mov rax, 8            ; sys_lseek = 8
    mov rsi, rdx          ; offset = current value in rdx
    xor rdx, rdx          ; SEEK_SET = 0
    syscall

    ; Write the replacement ("H4CK").
    mov rdi, rbx          ; file descriptor
    mov rax, 1            ; sys_write = 1
    mov rsi, replace      ; pointer to replacement string
    mov rdx, 4            ; write 4 bytes
    syscall

    ; Advance search pointer by 4 bytes to skip over the patched area.
    add rsi, 4
    add rdx, 4
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

finish_search:
    ; -----------------------------------------------------
    ; 8. If no patch was performed (r9 still 0), check if file is already patched.
    cmp r9, 1
    je close_fd_success    ; at least one patch was performed
    ; Search again for "H4CK" in the buffer.
    mov rsi, buffer
    xor rdx, rdx
search_loop2:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl close_fd_error    ; "H4CK" not found either → error
    mov eax, dword [replace]   ; load "H4CK"
    cmp dword [rsi], eax
    je close_fd_success        ; already patched
    inc rsi
    inc rdx
    cmp rdx, rcx
    jl search_loop2
    ; Neither "1337" nor "H4CK" was found.
    jmp close_fd_error

close_fd_success:
    ; -----------------------------------------------------
    ; 9. Close the file and exit with success.
    mov rdi, rbx          ; file descriptor
    mov rax, 3            ; sys_close = 3
    syscall
    xor rdi, rdi          ; exit code 0
    mov rax, 60           ; sys_exit = 60
    syscall

close_fd_error:
    ; -----------------------------------------------------
    ; Close the file and exit with error.
    mov rdi, rbx          ; file descriptor
    mov rax, 3            ; sys_close
    syscall
exit_error:
    mov rdi, 1            ; error exit code 1
    mov rax, 60           ; sys_exit
    syscall
