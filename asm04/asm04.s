section .bss
    user_input resb 6

section .text
    global _start

_start:
    mov eax, 0
    mov edi, 0
    mov esi, user_input
    mov edx, 6
    syscall

    sub byte [esi + eax - 1], '0'
    test eax, eax
    jz .exit

    xor ecx, ecx
    xor ebx, ebx
.convert_loop:
    movzx eax, byte [esi + ecx]
    cmp eax, '0'
    jl .done
    sub eax, '0'
    imul ebx, ebx, 10
    add ebx, eax
    inc ecx
    jmp .convert_loop
.done:

    test ebx, 2
    jnp .is_even

    mov eax, 60
    mov edi, 1
    syscall

.is_even:
    mov eax, 60
    xor edi, edi
    syscall

.exit:
    mov eax, 60
    xor edi, edi
    syscall
