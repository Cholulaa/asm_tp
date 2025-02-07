; Read file content
mov rdi, rbx        ; fd
mov rax, 0          ; sys_read
mov rsi, buffer     ; buffer
mov rdx, 1024       ; count
syscall

; Check read success and save the count
test rax, rax
jle .close
mov rcx, rax        ; Save number of bytes read in rcx

; Search for pattern
mov rsi, buffer     ; Source pointer
xor rdx, rdx        ; Offset counter

.loop:
    mov eax, [search]   ; Load search pattern into eax
    cmp [rsi], eax      ; Compare current 4 bytes with the pattern
    je .replace         ; If equal, jump to replacement

    inc rsi             ; Advance the pointer
    inc rdx             ; Increment offset
    cmp rdx, rcx        ; Compare offset to number of bytes read
    jl .loop
    jmp .close          ; Pattern not found, so close file

.replace:
    ; Seek to the found position
    mov rdi, rbx        ; fd
    mov rax, 8          ; sys_lseek
    mov rsi, rdx        ; offset
    xor rdx, rdx        ; SEEK_SET (0)
    syscall

    ; Write replacement string
    mov rdi, rbx        ; fd
    mov rax, 1          ; sys_write
    mov rsi, replace    ; replacement buffer ("H4CK")
    mov rdx, 4          ; number of bytes to write
    syscall

    ; Close file and exit successfully
    mov rdi, rbx
    mov rax, 3          ; sys_close
    syscall

    xor rdi, rdi        ; Success exit code (0)
    mov rax, 60         ; sys_exit
    syscall
