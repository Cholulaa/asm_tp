; asm16 - Advanced patcher for asm01
; Patches the binary (passed as parameter) so that it displays "H4CK" instead of "1337".
; Usage: ./asm16 asm01
; After patching, running:
;    ./asm01
; should output:
;    H4CK
;
; Enhancements in this version:
;  - Uses sys_lseek to determine file size and reads up to 16KB.
;  - Verifies the ELF header using the standard magic number.
;  - Searches the entire loaded portion for all occurrences of "1337"
;    and patches each one by seeking to the proper offset and writing "H4CK".
;  - If no "1337" is found, it checks for "H4CK" to detect an already-patched file.
;  - Exits with 0 on success, or 1 if any error occurs.
;
; Syscall numbers (from x64 syscall reference):
;   open:   2
;   read:   0
;   lseek:  8    (SEEK_SET = 0, SEEK_END = 2)
;   write:  1
;   close:  3
;   exit:   60

section .data
    search    db "1337"           ; 4-byte pattern to search for.
    replace   db "H4CK"           ; 4-byte replacement string.
    elf_magic dd 0x464C457F         ; ELF magic number (0x7F 'E' 'L' 'F' in little-endian)

section .bss
    buffer    resb 16384          ; Buffer to read up to 16KB from the file.

section .text
    global _start

_start:
    ; -----------------------------
    ; 1. Check that a filename was provided.
    ;    [rsp] = argc, [rsp+16] = argv[1]
    mov rdi, [rsp]         ; rdi = argc
    cmp rdi, 2
    jl exit_error          ; if no parameter, exit with error

    ; -----------------------------
    ; 2. Get the filename from argv[1]
    mov rdi, [rsp+16]      ; rdi -> filename

    ; -----------------------------
    ; 3. Open the file in read/write mode.
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR flag
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error          ; if open fails, exit error
    mov rbx, rax           ; save file descriptor in rbx

    ; -----------------------------
    ; 4. Determine file size.
    ;    lseek(fd, 0, SEEK_END) to get file size.
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0
    mov rdx, 2             ; SEEK_END = 2
    syscall
    mov r8, rax            ; r8 = file size

    ; Seek back to beginning (SEEK_SET = 0)
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0
    xor rdx, rdx           ; SEEK_SET = 0
    syscall

    ; Limit read size to buffer capacity (16KB)
    cmp r8, 16384
    jle read_file
    mov r8, 16384
read_file:
    ; -----------------------------
    ; 5. Read the file into buffer.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read
    mov rsi, buffer        ; destination buffer
    mov rdx, r8            ; number of bytes to read
    syscall
    test rax, rax
    jle close_fd_error     ; if nothing read, error
    mov rcx, rax           ; rcx = number of bytes read

    ; -----------------------------
    ; 6. Verify ELF header (first 4 bytes).
    cmp rcx, 4
    jl close_fd_error
    mov eax, dword [buffer]
    cmp eax, elf_magic
    jne close_fd_error     ; if not ELF, error

    ; -----------------------------
    ; 7. Search for "1337" in the buffer and patch occurrences.
    mov rsi, buffer        ; pointer into buffer
    xor rdx, rdx           ; offset counter = 0
    xor r9, r9             ; r9 = patched flag (0 = not patched yet)

search_loop:
    ; Check that at least 4 bytes remain.
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl finish_search

    mov eax, dword [search]    ; load "1337"
    cmp dword [rsi], eax       ; compare current 4 bytes
    je do_patch

    inc rsi                    ; advance pointer by one byte
    inc rdx                    ; increment offset counter
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

do_patch:
    mov r9, 1                  ; mark that we have patched at least once

    ; -----------------------------
    ; 8. Patch this occurrence:
    ;    Seek to the file offset where pattern was found.
    mov rdi, rbx             ; file descriptor
    mov rax, 8               ; sys_lseek
    mov rsi, rdx             ; offset = current value of rdx
    xor rdx, rdx             ; SEEK_SET = 0
    syscall

    ; Write the replacement string "H4CK".
    mov rdi, rbx             ; file descriptor
    mov rax, 1               ; sys_write
    mov rsi, replace         ; pointer to "H4CK"
    mov rdx, 4               ; write 4 bytes
    syscall

    ; (Optionally update the in-memory buffer so the patched region reads as "H4CK".)
    mov eax, dword [replace]
    mov dword [rsi], eax

    ; Advance our in‑memory pointer and offset by 4 to skip the patched block.
    add rsi, 4
    add rdx, 4
    cmp rdx, rcx
    jl search_loop
    jmp finish_search

finish_search:
    ; -----------------------------
    ; 9. If at least one patch was performed, we’re done.
    cmp r9, 1
    je close_fd_success

    ; If no patch was done, check if file already contains "H4CK".
    mov rsi, buffer
    xor rdx, rdx
search_loop2:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl close_fd_error       ; neither "1337" nor "H4CK" found → error
    mov eax, dword [replace]
    cmp dword [rsi], eax
    je close_fd_success     ; already patched!
    inc rsi
    inc rdx
    cmp rdx, rcx
    jl search_loop2
    jmp close_fd_error

close_fd_success:
    ; -----------------------------
    ; 10. Close the file and exit with success.
    mov rdi, rbx             ; file descriptor
    mov rax, 3               ; sys_close
    syscall
    xor rdi, rdi             ; exit code 0
    mov rax, 60              ; sys_exit
    syscall

close_fd_error:
    ; -----------------------------
    ; Close the file and exit with error.
    mov rdi, rbx             ; file descriptor
    mov rax, 3               ; sys_close
    syscall
exit_error:
    mov rdi, 1               ; exit code 1
    mov rax, 60              ; sys_exit
    syscall
