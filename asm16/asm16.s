; asm16 - Patcher for asm01: change "1337" to "H4CK"

section .data
    search  db "1337"    ; 4-byte pattern to look for
    replace db "H4CK"    ; 4-byte replacement string

section .bss
    buffer  resb 1024    ; temporary buffer for reading the file

section .text
    global _start

_start:
    ; Check that a filename was provided.
    mov rdi, [rsp]         ; argc is at [rsp]
    cmp rdi, 2             ; need at least 2 arguments (program name + filename)
    jl error               ; if not, exit with error

    ; Get pointer to filename (argv[1]).
    mov rdi, [rsp + 16]    ; argv[1] is at [rsp+16]

    ; Open the file (sys_open = 2).
    mov rax, 2             ; syscall number for open
    mov rsi, 2             ; O_RDWR flag (read and write)
    xor rdx, rdx           ; mode = 0 (unused here)
    syscall
    test rax, rax
    js error               ; if open failed (negative return), exit with error
    mov rbx, rax           ; save file descriptor in rbx

    ; Read up to 1024 bytes from the file (sys_read = 0).
    mov rdi, rbx           ; file descriptor
    mov rax, 0             ; syscall number for read
    mov rsi, buffer        ; buffer to store file data
    mov rdx, 1024          ; maximum number of bytes to read
    syscall
    test rax, rax
    jle close              ; if nothing was read or error occurred, jump to close
    mov rcx, rax           ; save the number of bytes read in rcx

    ; Search the buffer for the 4-byte pattern "1337".
    mov rsi, buffer        ; point to the start of the buffer
    xor rdx, rdx           ; offset counter = 0

search_loop:
    ; Compare 4 bytes at [rsi] with the search pattern.
    mov eax, dword [search]    ; load "1337" into eax
    cmp dword [rsi], eax       ; compare with current 4 bytes in the buffer
    je replace_pattern         ; if equal, jump to replacement

    inc rsi                    ; move pointer forward by one byte
    inc rdx                    ; increment offset counter
    cmp rdx, rcx               ; have we reached the end of the read data?
    jl search_loop             ; if not, continue looping

    ; Pattern not found: close the file and exit with error.
    jmp close

replace_pattern:
    ; Seek to the found offset (sys_lseek = 8).
    mov rdi, rbx            ; file descriptor
    mov rax, 8              ; syscall number for lseek
    mov rsi, rdx            ; offset where pattern was found
    xor rdx, rdx            ; SEEK_SET = 0
    syscall

    ; Write the replacement string (sys_write = 1).
    mov rdi, rbx            ; file descriptor
    mov rax, 1              ; syscall number for write
    mov rsi, replace        ; pointer to "H4CK"
    mov rdx, 4              ; write 4 bytes
    syscall

    ; Close the file (sys_close = 3) and exit successfully.
    mov rdi, rbx            ; file descriptor
    mov rax, 3              ; syscall number for close
    syscall
    xor rdi, rdi            ; exit code 0
    mov rax, 60             ; syscall number for exit
    syscall

close:
    ; Close the file if something went wrong (e.g. pattern not found).
    mov rdi, rbx            ; file descriptor
    mov rax, 3              ; sys_close
    syscall
error:
    ; Exit with error code 1.
    mov rdi, 1              ; exit code 1
    mov rax, 60             ; sys_exit
    syscall
