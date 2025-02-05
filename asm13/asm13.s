section .data
buffer: times 64 db 0

section .text
global _start

; asm13 : Vérifier si la chaîne lue sur stdin est un palindrome
; Retourne 0 si palindrome, 1 sinon.
; Ex.:
;   echo "radar"   | ./asm13 ; echo $?  => 0
;   echo "bonjour" | ./asm13 ; echo $?  => 1

_start:
    ; sys_read(0, buffer, 64)
    xor rax, rax        ; rax = 0 => sys_read
    mov rdi, rax        ; fd = 0 (stdin)
    mov rsi, buffer
    mov rdx, 64
    syscall             ; RAX = nombre d'octets lus

    mov rcx, rax        ; rcx = longueur lue
    test rcx, rcx
    jz palindrome       ; si 0 octet => palindrome => exit(0)

    ; Vérifier si le dernier caractère est un '\n'
    ; => si [buffer + (rcx - 1)] = '\n', on ignore ce dernier
    cmp byte [buffer + rcx - 1], 10
    jne .skip_newline
    dec rcx
    cmp rcx, 0
    je palindrome       ; s'il ne reste plus rien => palindrome
.skip_newline:

    ; Indices : rsi = 0 (début), rdi = rcx - 1 (fin)
    xor rsi, rsi
    mov rdi, rcx
    dec rdi

compare_loop:
    cmp rsi, rdi
    jge palindrome      ; si on a convergé => palindrome
    mov al, [buffer + rsi]
    mov bl, [buffer + rdi]
    cmp al, bl
    jne not_palindrome
    inc rsi
    dec rdi
    jmp compare_loop

palindrome:
    mov rax, 60
    xor rdi, rdi
    syscall

not_palindrome:
    mov rax, 60
    mov rdi, 1
    syscall
