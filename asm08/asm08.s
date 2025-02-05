section .data
buffer: times 64 db 0

section .text
global _start

; asm08: Somme des entiers < n
; Exemples:
;   ./asm08 5   => 1+2+3+4 = 10
;   ./asm08 1   => 0
;   ./asm08 10  => 45
; Retourne 0 en cas de succès, ou 1 s'il y a une erreur (ex: pas de param).

_start:
    ; Vérifie qu'on a un paramètre (argv[1])
    mov rsi, [rsp+16]
    test rsi, rsi
    jz error

    ; Parse l'entier => RAX
    call parse

    ; Si n <= 1 => somme = 0
    cmp rax, 2
    jb .zero

    ; Sinon somme(1..(n-1)) = n*(n-1)/2
    mov rbx, rax
    dec rbx
    mul rbx       ; RDX:RAX = n*(n-1)
    xor rdx, rdx
    mov rcx, 2
    div rcx       ; RAX = (n*(n-1))/2
    jmp .print

.zero:
    xor rax, rax

.print:
    call print
    mov rax, 60
    xor rdi, rdi
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall

; -----------------------------------------------------------------------------
; parse:
;   RSI => pointeur sur argv[1]
;   RAX => l'entier parsé (>= 0)
;   Si pas de digit, on renvoie 0 comme fallback (pour éviter un exit(1) forcé)
; -----------------------------------------------------------------------------
parse:
    xor rax, rax
.parse_loop:
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
    jmp .parse_loop
.done:
    ret

; -----------------------------------------------------------------------------
; print:
;   Affiche RAX en ASCII (décimal) sur stdout
; -----------------------------------------------------------------------------
print:
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
