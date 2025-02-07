; asm16 - Patch asm01 so that it displays "H4CK" instead of "1337"
; Usage: ./asm16 asm01
; After patching, running:
;    ./asm01
; should output:
;    H4CK
;
; This patcher does the following:
; 1. Verifies that a filename was provided and opens the file in O_RDWR.
; 2. Reads the first 4 bytes to check the ELF header.
; 3. Seeks to file offset 0x2000 (the .data section as indicated by radare2).
; 4. Reads 5 bytes from that offset (expected "1337\n") and verifies that the
;    first 4 bytes equal "1337".
; 5. Seeks back to 0x2000 and writes "H4CK" (4 bytes) over "1337".
;
; Syscall numbers (x64):
;   open:   2
;   read:   0
;   lseek:  8    (SEEK_SET = 0, SEEK_END = 2)
;   write:  1
;   close:  3
;   exit:   60

section .data
    elf_magic dd 0x464C457F       ; 0x7F 'E' 'L' 'F'
    ; expected data in .data section: "1337\n"
    ; We'll compare the first 4 bytes ("1337").
    ; In ASCII: '1' = 0x31, '3' = 0x33, '3' = 0x33, '7' = 0x37.
    ; In little-endian, the dword is: 0x37333131.
    expected_dword dd 0x37333131
    replacement    db "H4CK"       ; 4-byte replacement string

section .bss
    header    resb 4              ; To hold ELF header (first 4 bytes)
    data_read resb 5              ; To hold 5 bytes read from .data

section .text
    global _start

_start:
    ; --- 1. Check that a filename was provided.
    mov rdi, [rsp]         ; argc
    cmp rdi, 2
    jl exit_error          ; exit if fewer than 2 arguments

    ; --- 2. Get the filename (argv[1])
    mov rdi, [rsp+16]      ; pointer to filename

    ; --- 3. Open the file in read/write mode.
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR
    xor rdx, rdx           ; mode = 0
    syscall
    test rax, rax
    js exit_error          ; on error, exit
    mov rbx, rax           ; save file descriptor in rbx

    ; --- 4. Read the ELF header (first 4 bytes) to verify the file.
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; sys_read
    mov rsi, header
    mov rdx, 4
    syscall
    cmp rax, 4
    jne close_fd_error
    mov eax, dword [header]
    cmp eax, elf_magic
    jne close_fd_error

    ; --- 5. Seek to .data section offset (0x2000)
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0x2000        ; offset = 0x2000 (from radare2)
    xor rdx, rdx           ; SEEK_SET
    syscall

    ; --- 6. Read 5 bytes from .data section.
    mov rdi, rbx
    mov rax, 0             ; sys_read
    mov rsi, data_read
    mov rdx, 5
    syscall
    cmp rax, 5
    jne close_fd_error

    ; --- 7. Verify that the first 4 bytes equal "1337".
    mov eax, dword [data_read]
    cmp eax, dword [expected_dword]
    jne close_fd_error

    ; --- 8. Seek back to offset 0x2000.
    mov rdi, rbx
    mov rax, 8             ; sys_lseek
    mov rsi, 0x2000
    xor rdx, rdx           ; SEEK_SET
    syscall

    ; --- 9. Write "H4CK" (4 bytes) at that offset.
    mov rdi, rbx
    mov rax, 1             ; sys_write
    mov rsi, replacement
    mov rdx, 4
    syscall

    ; --- 10. Close the file and exit with success.
    mov rdi, rbx
    mov rax, 3             ; sys_close
    syscall
    xor rdi, rdi           ; exit code 0
    mov rax, 60            ; sys_exit
    syscall

close_fd_error:
    mov rdi, rbx
    mov rax, 3
    syscall
exit_error:
    mov rdi, 1             ; exit code 1
    mov rax, 60
    syscall
