section .data
    buffer db 20 dup(0)

section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments
    pop rcx         ; argc
    cmp rcx, 3      ; prog + 2 args = 3
    jne exit_error

    ; Ignorer argv[0] (nom du programme)
    pop rcx
    
    ; Premier argument
    pop rcx
    mov rdi, rcx
    call atoi       ; Convertir en entier
    mov r12, rax    ; Sauvegarder le premier nombre
    
    ; Deuxième argument
    pop rcx
    mov rdi, rcx
    call atoi       ; Convertir en entier
    
    ; Additionner les nombres
    add rax, r12
    
    ; Convertir le résultat en chaîne et l'afficher
    mov rdi, rax
    mov rsi, buffer
    call itoa
    
    ; Calculer la longueur de la chaîne résultat
    mov rdi, buffer
    call strlen
    
    ; Afficher le résultat
    mov rdx, rax    ; longueur
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, buffer
    syscall
    
    ; Ajouter un retour à la ligne
    mov [buffer], byte 0xA
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 1
    syscall
    
    jmp exit_success

; Convertir ASCII vers entier
atoi:
    push rbx
    mov rsi, rdi        ; Sauvegarder le pointeur
    xor rax, rax        ; Initialiser le résultat
    mov rbx, 1          ; Signe positif par défaut

    ; Vérifier le signe
    cmp byte [rsi], '-'
    jne .process_digits
    inc rsi             ; Sauter le signe moins
    neg rbx             ; Changer le signe

.process_digits:
    movzx rcx, byte [rsi]
    test rcx, rcx
    jz .done
    
    cmp rcx, '0'
    jb .done
    cmp rcx, '9'
    ja .done
    
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    
    inc rsi
    jmp .process_digits

.done:
    imul rax, rbx       ; Appliquer le signe
    pop rbx
    ret

; Convertir entier vers ASCII
itoa:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Vérifier si négatif
    test rdi, rdi
    jns .positive
    neg rdi
    mov byte [rsi], '-'
    inc rsi
    
.positive:
    mov rax, rdi
    mov rbx, 10
    mov rcx, 0          ; Compteur de chiffres
    
.divide_loop:
    xor rdx, rdx
    div rbx
    push rdx            ; Empiler le reste
    inc rcx
    test rax, rax
    jnz .divide_loop
    
.build_string:
    pop rax
    add al, '0'
    mov [rsi], al
    inc rsi
    dec rcx
    jnz .build_string
    
    mov byte [rsi], 0   ; Null-terminer
    
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Calculer la longueur d'une chaîne
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

exit_success:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; status = 0
    syscall

exit_error:
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; status = 1
    syscall
