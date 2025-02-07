; asm16 - Advanced patcher for asm01
; Patches the binary (passed as parameter) so that it displays "H4CK" instead of "1337".
; Usage: ./asm16 asm01
; After patching, running:
;    ./asm01
; should output:
;    H4CK
;
; Syscall numbers (x64):
;   open:   2
;   read:   0
;   lseek:  8    (SEEK_SET = 0, SEEK_END = 2)
;   write:  1
;   close:  3
;   exit:   60

section .data
    search    db "1337"           ; 4-byte search pattern (will match the first 4 bytes of "1337\n")
    replace   db "H4CK"           ; 4-byte replacement string
    elf_magic dd 0x464C457F         ; ELF magic: 0x7F 'E' 'L' 'F'

section .bss
    buffer    resb 16384          ; Buffer for up to 16KB of file data

section .text
    global _start

_start:
    ; -----------------------------
    ; 1. Check that a filename was provided.
    mov rdi, [rsp]         ; rdi = argc
    cmp rdi, 2
    jl exit_error          ; if fewer than 2 arguments, error

    ; -----------------------------
    ; 2. Get filename from argv[1].
    mov rdi, [rsp+16]      ; rdi -> filename

    ; -----------------------------
    ; 3. Open the file in read-write mode.
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error          ; if open failed, exit error
    mov rbx, rax           ; save file descriptor in rbx

    ; -----------------------------
    ; 4. Determine file size via lseek.
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0
    mov rdx, 2             ; SEEK_END = 2
    syscall
    mov r8, rax            ; r8 = file size

    ; Seek back to beginning.
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
    ; 5. Read up to r8 bytes from the file into buffer.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read
    mov rsi, buffer        ; destination buffer
    mov rdx, r8            ; number of bytes to read
    syscall
    test rax, rax
    jle close_fd_error     ; if nothing read, error
    mov rcx, rax           ; rcx = number of bytes read

    ; -----------------------------
    ; 6. Verify ELF header: first 4 bytes must equal elf_magic.
    cmp rcx, 4
    jl close_fd_error
    mov eax, dword [buffer]
    cmp eax, elf_magic
    jne close_fd_error

    ; -----------------------------
    ; 7. Scan the buffer for "1337" and patch occurrences.
    ; Set up our scanning offset in rdx.
    xor rdx, rdx           ; rdx = 0 (offset)
patch_loop:
    ; Check if at least 4 bytes remain.
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl finish_search       ; if fewer than 4 bytes remain, stop scanning

    ; Compare dword at [buffer+rdx] with our search pattern.
    mov eax, dword [buffer + rdx]
    cmp eax, dword [search]
    je do_patch

    ; No match; increment offset by 1.
    inc rdx
    jmp patch_loop

do_patch:
    ; Mark that we performed a patch.
    mov r9, 1              ; r9 = 1 indicates at least one patch
    ; Save the current offset in r10.
    mov r10, rdx
    ; -----------------------------
    ; 8. Seek to offset (r10) in the file.
    mov rdi, rbx           ; file descriptor
    mov rax, 8             ; sys_lseek
    mov rsi, r10           ; offset = current search offset
    xor rdx, rdx           ; SEEK_SET
    syscall

    ; -----------------------------
    ; 9. Write the replacement string "H4CK".
    mov rdi, rbx           ; file descriptor
    mov rax, 1             ; sys_write
    mov rsi, replace       ; pointer to replacement string
    mov rdx, 4             ; write 4 bytes
    syscall

    ; Optionally update our in‑memory buffer so it reflects the patch.
    mov eax, dword [replace]
    mov dword [buffer + r10], eax

    ; Advance offset by 4 (skip over the patched region).
    add rdx, 4             ; we want to increment our scanning offset by 4...
    add rdx, r10           ; but r10 is the current offset, so set: new offset = r10 + 4.
    ; Alternatively, simply: add rdx, 4 and then adjust pointer.
    ; Here we recalc: set rdx = r10 + 4.
    mov rdx, r10
    add rdx, 4
    jmp patch_loop

finish_search:
    ; -----------------------------
    ; 10. If no patch was done, check if file already contains "H4CK".
    cmp r9, 1
    je close_fd_success   ; if patched at least once, we succeed
    ; Otherwise, scan for "H4CK" in the buffer.
    xor rdx, rdx          ; reset offset for second scan
scan2:
    mov r10, rcx
    sub r10, rdx
    cmp r10, 4
    jl close_fd_error     ; not found → error
    mov eax, dword [buffer + rdx]
    cmp eax, dword [replace]
    je close_fd_success   ; if found "H4CK", file already patched
    inc rdx
    jmp scan2

close_fd_success:
    ; -----------------------------
    ; 11. Close the file and exit with success.
    mov rdi, rbx          ; file descriptor
    mov rax, 3            ; sys_close
    syscall
    xor rdi, rdi          ; exit code 0
    mov rax, 60           ; sys_exit
    syscall

close_fd_error:
    ; -----------------------------
    ; Close file and exit with error.
    mov rdi, rbx          ; file descriptor
    mov rax, 3            ; sys_close
    syscall
exit_error:
    mov rdi, 1            ; exit code 1
    mov rax, 60           ; sys_exit
    syscall
