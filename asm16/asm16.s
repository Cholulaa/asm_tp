; asm16 - Patch asm01 so that it displays "H4CK" instead of "1337"
; Usage: ./asm16 asm01
; After patching, running:
;   ./asm01
; should output:
;   H4CK
;
; This version:
;  - Opens the file and uses lseek to determine file size.
;  - Reads up to 16KB from the file.
;  - Verifies that the ELF header is correct.
;  - Scans the loaded data for the 4-byte pattern "1337" (ignoring the newline).
;  - When found, seeks to that offset and writes "H4CK".
;  - If no "1337" is found, checks for "H4CK" to allow for an already-patched file.
;
; Syscall numbers (x64):
;   open:   2
;   read:   0
;   lseek:  8   (SEEK_SET = 0, SEEK_END = 2)
;   write:  1
;   close:  3
;   exit:   60

section .data
    search    db "1337"           ; The 4-byte search pattern.
    replace   db "H4CK"           ; The 4-byte replacement string.
    elf_magic dd 0x464C457F         ; ELF magic number: 0x7F 'E' 'L' 'F'

section .bss
    buffer    resb 16384          ; Buffer for up to 16KB of file data

section .text
    global _start

_start:
    ; 1. Verify that a filename was provided.
    mov rdi, [rsp]         ; argc
    cmp rdi, 2
    jl exit_error

    ; 2. Get filename from argv[1]
    mov rdi, [rsp+16]      ; pointer to filename

    ; 3. Open the file (O_RDWR)
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error
    mov rbx, rax           ; save file descriptor

    ; 4. Determine file size with lseek(SEEK_END)
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0
    mov rdx, 2             ; SEEK_END
    syscall
    mov r8, rax            ; r8 = file size

    ; Seek back to the beginning (SEEK_SET)
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
    ; 5. Read the file into buffer.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read
    mov rsi, buffer
    mov rdx, r8            ; number of bytes to read
    syscall
    test rax, rax
    jle close_fd_error
    mov rcx, rax           ; rcx = number of bytes read

    ; 6. Verify ELF header (first 4 bytes)
    cmp rcx, 4
    jl close_fd_error
    mov eax, dword [buffer]
    cmp eax, elf_magic
    jne close_fd_error

    ; 7. Scan the buffer for "1337"
    xor rdx, rdx           ; offset = 0
patch_loop:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl finish_search     ; fewer than 4 bytes remain
    mov eax, dword [buffer + rdx]
    cmp eax, dword [search]
    je do_patch
    inc rdx
    jmp patch_loop

do_patch:
    ; Mark that we patched at least once.
    mov r9, 1             ; r9 = 1 indicates a patch was done
    ; Save the current offset in r10.
    mov r10, rdx
    ; 8. Seek to the offset in the file.
    mov rdi, rbx
    mov rax, 8            ; sys_lseek
    mov rsi, r10          ; offset
    xor rdx, rdx          ; SEEK_SET
    syscall
    ; 9. Write "H4CK" (4 bytes)
    mov rdi, rbx
    mov rax, 1            ; sys_write
    mov rsi, replace
    mov rdx, 4
    syscall
    ; Optionally update the in-memory buffer.
    mov eax, dword [replace]
    mov dword [buffer + r10], eax
    ; Advance offset by 4.
    mov rdx, r10
    add rdx, 4
    jmp patch_loop

finish_search:
    ; 10. If no patch was done, check for "H4CK" already.
    cmp r9, 1
    je close_fd_success
    xor rdx, rdx
scan2:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl close_fd_error
    mov eax, dword [buffer + rdx]
    cmp eax, dword [replace]
    je close_fd_success
    inc rdx
    jmp scan2

close_fd_success:
    ; 11. Close the file and exit with code 0.
    mov rdi, rbx
    mov rax, 3            ; sys_close
    syscall
    xor rdi, rdi
    mov rax, 60           ; sys_exit
    syscall

close_fd_error:
    ; Close file and exit with error.
    mov rdi, rbx
    mov rax, 3
    syscall
exit_error:
    mov rdi, 1
    mov rax, 60
    syscall
