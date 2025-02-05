section .data
buffer: times 64 db 0

section .text
global _start

; asm11: Compter le nombre de voyelles dans l'entrée standard
;        On considère a, e, i, o, u, y (en minuscules ou majuscules) comme voyelles.
; Exemple:
;   echo "assemblage" | ./asm11    => 4
;   echo "HELLO WORLD" | ./asm11   => 3
;   echo "bcdfghjklmnpqrstvwxyz" | ./asm11 => 1 (car 'y' est compté)
; Retourne 0 si tout va bien.

_start:
    ; sys_read(0, buffer, 64)
    xor rax, rax         ; rax = 0 => sys_read
    mov rdi, rax         ; file descriptor = 0 (stdin)
    mov rsi, buffer
    mov rdx, 64
    syscall
    mov rcx, rax         ; rcx = nb d'octets lus
    xor rbx, rbx         ; rbx = compteur de voyelles

.main_loop:
    test rcx, rcx
    jz .done
    mov al, [rsi]
    inc rsi
    dec rcx
    call is_vowel
    add rbx, rax         ; ajoute 1 si voyelle, 0 sinon
    jmp .main_loop

.done:
    ; rbx = total de voyelles
    mov rax, rbx
    call print_decimal
    mov rax, 60
    xor rdi, rdi
    syscall

; is_vowel: AL => caractère, RAX => 1 si voyelle, 0 sinon
; On inclut 'y' / 'Y' comme voyelle, selon le test donné.
is_vowel:
    cmp al, 'a'
    je .ret1
    cmp al, 'e'
    je .ret1
    cmp al, 'i'
    je .ret1
    cmp al, 'o'
    je .ret1
    cmp al, 'u'
    je .ret1
    cmp al, 'y'
    je .ret1

    cmp al, 'A'
    je .ret1
    cmp al, 'E'
    je .ret1
    cmp al, 'I'
    je .ret1
    cmp al, 'O'
    je .ret1
    cmp al, 'U'
    je .ret1
    cmp al, 'Y'
    je .ret1
    xor rax, rax
    ret
.ret1:
    mov rax, 1
    ret

; print_decimal: RAX => entier (0..)
; Affiche en ASCII sur stdout
print_decimal:
    test rax, rax
    jnz .convert
    mov byte [buffer], '0'
    mov rsi, buffer
    mov rdx, 1
    jmp .write

.convert:
    mov rbx, rax
    lea rdi, [buffer+63]
.conv_loop:
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 10
    div rcx
    mov rbx, rax
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rbx, rbx
    jnz .conv_loop
    inc rdi
    mov rsi, rdi
    mov rdx, buffer+64
    sub rdx, rdi

.write:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
