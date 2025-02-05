section .data
buffer: times 64 db 0

section .text
global _start

; asm10 : Afficher le maximum de trois entiers signés passés en paramètres
; Exemple :
;   ./asm10 7 3 5   => 7
;   ./asm10 -1 -2 -3 => -1
;   ./asm10 5 5 5   => 5
;   ./asm10 10 15 5 => 15
; Si moins de 3 paramètres => exit code 1

; Assemble & link:
;   nasm -f elf64 asm10.asm -o asm10.o
;   ld asm10.o -o asm10

_start:
    mov r8, [rsp]           ; argc
    cmp r8, 4               ; besoin de 3 paramètres => argc >= 4 (argv[0]..argv[3])
    jl err

    ; Lire argv[1] => RBX
    mov rsi, [rsp+16]
    call parse
    mov rbx, rax

    ; Lire argv[2] => RCX
    mov rsi, [rsp+24]
    call parse
    mov rcx, rax

    ; Lire argv[3] => RDX
    mov rsi, [rsp+32]
    call parse
    mov rdx, rax

    ; Comparer pour trouver le max
    cmp rcx, rbx
    jle .check3
    mov rbx, rcx
.check3:
    cmp rdx, rbx
    jle .max_done
    mov rbx, rdx
.max_done:
    ; RBX = max
    mov rax, rbx
    call print_signed

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

err:
    ; exit(1)
    mov rax, 60
    mov rdi, 1
    syscall

; ------------------------------------------------------------------------
; parse : lit un entier signé dans la chaîne RSI => RAX
; ------------------------------------------------------------------------
parse:
    xor r8, r8         ; flag de signe
    mov dl, [rsi]
    cmp dl, '-'
    jne .digits
    mov r8, 1
    inc rsi
.digits:
    xor rax, rax
.loop:
    mov dl, [rsi]
    test dl, dl
    jz .done
    cmp dl, 10
    je .done
    sub dl, '0'
    jl .done
    cmp dl, 9
    jg .done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .loop
.done:
    test r8, r8
    jz .ret
    neg rax
.ret:
    ret

; ------------------------------------------------------------------------
; print_signed : affiche RAX (entier signé) en decimal sur stdout
; ------------------------------------------------------------------------
print_signed:
    test rax, rax
    jns .positive
    mov byte [buffer], '-'
    neg rax
    lea rdi, [buffer+1]
    jmp .convert
.positive:
    lea rdi, [buffer]
.convert:
    ; On convertit la valeur absolue dans [rdi..]
    mov rcx, rax
    test rcx, rcx
    jnz .has_value
    mov byte [rdi], '0'
    inc rdi
    jmp .write
.has_value:
    ; On écrit les chiffres en sens inverse dans [buffer+63..] puis on pointera dessus
    lea rsi, [buffer+63]
.loop_digits:
    xor rdx, rdx
    mov rax, rcx
    mov r8, 10
    div r8
    mov rcx, rax
    add rdx, '0'
    mov byte [rsi], dl
    dec rsi
    test rcx, rcx
    jnz .loop_digits
    inc rsi

    ; now [rsi..buffer+63] contient les digits inversés
    ; on doit copier vers [rdi..] en ordre normal
    ; longueur = (buffer+64) - rsi
    mov rax, buffer+64
    sub rax, rsi         ; rax = nb de caractères
.copy:
    mov dl, [rsi]
    mov [rdi], dl
    inc rdi
    inc rsi
    dec rax
    jnz .copy

.write:
    mov rax, 1           ; sys_write
    mov rsi, buffer      ; début du buffer
    sub rdi, buffer
    mov rdx, rdi         ; longueur totale
    mov rdi, 1           ; stdout
    syscall
    ret
