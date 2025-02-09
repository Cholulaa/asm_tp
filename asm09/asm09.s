section .data
    tampon: times 64 db 0
    flag_bin: db '-b', 0

section .text
    global _start

_start:
    mov r8, [rsp]
    cmp r8, 1
    jbe erreur
    mov rsi, [rsp+16]
    call strcmp_b
    test rax, rax
    jz verifier_bin
do_hex:
    mov rsi, [rsp+16]
    call parse_int
    mov rbx, rax
    call print_hex
    jmp succes
verifier_bin:
    cmp r8, 2
    jbe erreur
    mov rsi, [rsp+24]
    call parse_int
    mov rbx, rax
    call print_bin
    jmp succes
succes:
    mov rax, 60
    xor rdi, rdi
    syscall
erreur:
    mov rax, 60
    mov rdi, 1
    syscall

strcmp_b:
    push rdi
    mov rdi, flag_bin
.loop_cmp:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne diff
    test al, al
    jz same
    inc rsi
    inc rdi
    jmp .loop_cmp
diff:
    mov rax, 1
    pop rdi
    ret
same:
    xor rax, rax
    pop rdi
    ret

parse_int:
    xor rax, rax
.p_loop:
    mov dl, [rsi]
    test dl, dl
    jz done
    cmp dl, 10
    je done
    sub dl, '0'
    jl done
    cmp dl, 9
    jg done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    jmp .p_loop
done:
    ret

print_hex:
    test rbx, rbx
    jnz convertir_hex
    mov byte [tampon], '0'
    mov rsi, tampon
    mov rdx, 1
    jmp ecrire
convertir_hex:
    mov rax, rbx
    lea rdi, [tampon+63]
.hex_loop:
    xor rdx, rdx
    mov rcx, 16
    div rcx
    cmp rdx, 9
    jg alpha
    add rdx, '0'
    jmp store
alpha:
    add rdx, 'A' - 10
store:
    mov byte [rdi], dl
    dec rdi
    test rax, rax
    jnz .hex_loop
    inc rdi
    mov rsi, rdi
    mov rdx, tampon+64
    sub rdx, rdi
ecrire:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_bin:
    test rbx, rbx
    jnz convertir_bin
    mov byte [tampon], '0'
    mov rsi, tampon
    mov rdx, 1
    jmp ecrire_bin
convertir_bin:
    mov rax, rbx
    lea rdi, [tampon+63]
.bin_loop:
    xor rdx, rdx
    mov rcx, 2
    div rcx
    add rdx, '0'
    mov byte [rdi], dl
    dec rdi
    test rax, rax
    jnz .bin_loop
    inc rdi
    mov rsi, rdi
    mov rdx, tampon+64
    sub rdx, rdi
ecrire_bin:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
