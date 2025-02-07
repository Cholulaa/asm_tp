section .data
    search db "1337"   ; La chaîne à rechercher
    replace db "H4CK"  ; La nouvelle chaîne
    search_len equ 4   ; Longueur de la chaîne à remplacer

section .bss
    buffer resb 4096   ; Buffer pour lire le fichier (augmente la taille)

section .text
    global _start

%define SYS_open 2
%define SYS_read 0
%define SYS_write 1
%define SYS_lseek 8
%define SYS_close 3
%define SYS_exit 60
%define O_RDWR 2
%define SEEK_SET 0

_start:
    ; Vérifier si un argument est fourni
    mov r8, [rsp]      
    cmp r8, 2
    jl .error          

    ; Ouvrir le fichier asm01 en lecture/écriture
    mov rdi, [rsp+16]  
    mov rax, SYS_open
    mov rsi, O_RDWR
    xor rdx, rdx
    syscall
    cmp rax, 0
    js .error

    mov rbx, rax       ; Stocker le file descriptor

    ; Lire le fichier en mémoire
    mov rdi, rbx
    mov rsi, buffer
    mov rdx, 4096
    mov rax, SYS_read
    syscall
    cmp rax, 0
    jle .close_error

    mov rcx, rax       ; Nombre d'octets lus
    mov rsi, buffer

    ; Rechercher "1337" octet par octet
.find_loop:
    cmp rcx, search_len
    jl .close_error    ; Si pas trouvé, quitter

    mov rdi, search
    mov rdx, search_len
    push rsi           ; Sauvegarde rsi (position actuelle)

.compare:
    mov al, [rsi]
    cmp al, [rdi]
    jne .next_byte
    inc rsi
    inc rdi
    dec rdx
    jnz .compare

    ; Trouvé ! Calculer l'offset
    pop rsi
    sub rsi, buffer    

    ; Déplacer le curseur au bon offset
    mov rdi, rbx       
    mov rdx, SEEK_SET  
    mov rax, SYS_lseek
    syscall

    ; Écrire "H4CK"
    mov rdi, rbx
    mov rsi, replace
    mov rdx, search_len
    mov rax, SYS_write
    syscall

    jmp .close_success

.next_byte:
    pop rsi            ; Restaurer rsi
    inc rsi
    dec rcx
    jmp .find_loop

.close_success:
    mov rax, SYS_close
    mov rdi, rbx
    syscall
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

.close_error:
    mov rax, SYS_close
    mov rdi, rbx
    syscall

.error:
    mov rax, SYS_exit
    mov rdi, 1
    syscall
