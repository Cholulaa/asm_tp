section .data
    userMessage db '1337', 0xA
    expectedInput db '42', 0

section .text
    global _start

_start:
    ; Lire l'adresse du deuxième argument (argv[1])
    mov rdi, [rsp + 8 * 2]  ; rsp + 8 (return address) + 8 (argc)
    test rdi, rdi
    jz exitFailure  ; Si aucun argument n'est fourni, sortir avec échec

    ; Comparer l'argument fourni avec l'entrée attendue
    mov rsi, expectedInput
    call compareStrings

    test al, al
    jnz exitFailure

    ; Afficher le message si l'entrée est "42"
    mov rdi, 1
    mov rax, 1
    mov rsi, userMessage
    mov rdx, 5
    syscall

    ; Sortir avec le code de statut 0
    xor edi, edi
    mov eax, 60
    syscall

exitFailure:
    ; Sortir avec le code de statut 1
    mov eax, 60
    mov edi, 1
    syscall

compareStrings:
    xor rax, rax
.nextChar:
    mov al, [rsi]
    cmp al, byte [rdi]
    jne .notequal
    test al, al
    jz .equal
    inc rsi
    inc rdi
    jmp .nextChar
.equal:
    ret
.notequal:
    mov al, 1
    ret
