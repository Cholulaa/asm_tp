; asm16 - Advanced patcher for asm01
; Patches the binary (passed as parameter) so that it displays "H4CK" instead of "1337".
; Usage: ./asm16 asm01
; After patching, running:
;   ./asm01
; should output:
;   H4CK
;
; Enhancements:
;   - Verifies the ELF header.
;   - Reads 4096 bytes instead of 1024.
;   - Scans for all occurrences of "1337" and patches them.
;   - If no "1337" is found, it searches for "H4CK" to allow for an already-patched file.
;   - Exits with 0 on success, or 1 if an error occurs.

section .data
    search    db "1337"         ; 4-byte pattern to search for.
    replace   db "H4CK"         ; 4-byte replacement string.
    elf_magic dd 0x464C457F       ; ELF magic: 0x7F 'E' 'L' 'F' (little-endian)

section .bss
    buffer    resb 4096         ; Buffer to read up to 4096 bytes from the file.

section .text
    global _start

_start:
    ; -------------------------------------------
    ; 1. Check that a filename was provided.
    ;    [rsp] = argc, [rsp+16] = argv[1]
    mov rdi, [rsp]         ; rdi = argc
    cmp rdi, 2
    jl exit_error          ; no parameter → error

    ; -------------------------------------------
    ; 2. Get the filename from argv[1]
    mov rdi, [rsp+16]      ; rdi -> filename

    ; -------------------------------------------
    ; 3. Open the file in read-write mode.
    mov rax, 2             ; sys_open = 2
    mov rsi, 2             ; flag: O_RDWR
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error          ; if open failed, exit with error
    mov rbx, rax           ; save file descriptor in rbx

    ; -------------------------------------------
    ; 4. Read up to 4096 bytes from the file.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read = 0
    mov rsi, buffer        ; buffer to store file content
    mov rdx, 4096          ; read up to 4096 bytes
    syscall
    test rax, rax
    jle close_fd_error     ; nothing read or error
    mov rcx, rax           ; rcx = number of bytes read

    ; -------------------------------------------
    ; 5. Verify that the file is an ELF binary.
    cmp rcx, 4             ; need at least 4 bytes for header check
    jl close_fd_error
    mov eax, dword [buffer]
    cmp eax, elf_magic
    jne close_fd_error     ; not an ELF file → error

    ; -------------------------------------------
    ; 6. Search for the pattern "1337" in the buffer.
    ;    (Patch every occurrence found.)
    mov rsi, buffer        ; pointer into buffer
    xor rdx, rdx           ; offset counter = 0
    xor r9, r9             ; r9 will be used as a flag (0 = no patch done)

search_loop:
    ; Ensure at least 4 bytes remain.
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl finish_search       ; not enough bytes left

    mov eax, dword [search]    ; load 4-byte "1337"
    cmp dword [rsi], eax       ; compare with 4 bytes at [rsi]
    je do_patch

    inc rsi                    ; advance pointer by one byte
    inc rdx                    ; increment offset counter
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

do_patch:
    mov r9, 1                  ; mark that we patched at least once
    ; -------------------------------------------
    ; 7. Patch this occurrence.
    ;    Seek to the offset in the file where the pattern was found.
    mov rdi, rbx               ; file descriptor
    mov rax, 8                 ; sys_lseek = 8
    mov rsi, rdx               ; offset (in file) = current value in rdx
    xor rdx, rdx               ; SEEK_SET = 0
    syscall

    ; Write the replacement string "H4CK".
    mov rdi, rbx               ; file descriptor
    mov rax, 1                 ; sys_write = 1
    mov rsi, replace           ; pointer to "H4CK"
    mov rdx, 4                 ; write 4 bytes
    syscall

    ; Advance our in‑memory pointer by 4 bytes to skip over the patched region.
    add rsi, 4
    add rdx, 4
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

finish_search:
    ; -------------------------------------------
    ; 8. If no patch was performed, check if the file is already patched.
    cmp r9, 1
    je close_fd_success      ; at least one patch was done → success

    ; Search for "H4CK" in the buffer.
    mov rsi, buffer
    xor rdx, rdx
search_loop2:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl close_fd_error        ; neither "1337" nor "H4CK" found → error
    mov eax, dword [replace] ; load "H4CK"
    cmp dword [rsi], eax
    je close_fd_success      ; already patched
    inc rsi
    inc rdx
    cmp rdx, rcx
    jl search_loop2
    jmp close_fd_error

close_fd_success:
    ; -------------------------------------------
    ; 9. Close the file and exit with success (exit code 0).
    mov rdi, rbx             ; file descriptor
    mov rax, 3               ; sys_close = 3
    syscall
    xor rdi, rdi             ; exit code 0
    mov rax, 60              ; sys_exit = 60
    syscall

close_fd_error:
    ; -------------------------------------------
    ; Close the file and exit with error (exit code 1).
    mov rdi, rbx             ; file descriptor
    mov rax, 3               ; sys_close
    syscall
exit_error:
    mov rdi, 1               ; error exit code 1
    mov rax, 60              ; sys_exit = 60
    syscall
