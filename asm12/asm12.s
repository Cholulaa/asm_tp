section .data
buffer: times 64 db 0

section .text
global _start

; asm12 : Inverser la chaîne lue sur stdin et l'afficher
; Ex:
;   echo "abcd" | ./asm12
;   => "dcba"

_start:
    ; sys_read(0, buffer, 64)
    xor rax, rax         ; rax = 0 => sys_read
    mov rdi, rax         ; stdin
    mov rsi, buffer
    mov rdx, 64
    syscall              ; nombre d'octets lus dans rax
    mov rcx, rax         ; rcx = length

    ; si aucun caractère lu, on sort directement
    test rcx, rcx
    jz .done

    ; enlever éventuel '\n' à la fin
    lea rdi, [buffer + rcx - 1]
    cmp byte [rdi], 10
    jne .reverse
    dec rcx

.reverse:
    ; RCX = longueur à inverser
    ; pointeurs: start (rsi = buffer) et end (rdi = buffer + rcx - 1)
    mov rsi, buffer
    lea rdi, [buffer + rcx - 1]

.loop:
    cmp rsi, rdi
    jge .write
    mov al, [rsi]
    mov bl, [rdi]
    mov [rsi], bl
    mov [rdi], al
    inc rsi
    dec rdi
    jmp .loop

.write:
    ; écrire la chaîne inversée
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, buffer
    mov rdx, rcx
    syscall

.done:
    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
