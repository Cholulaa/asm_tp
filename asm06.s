section .data
    user_input db "Enter a number: ", 10
        
section .bss
    nombre resb 6

section .text
    global _start

_start:
    mov eax, 1
    mov edi, 1
    mov esi, user_input
    mov edx, 17
    syscall 

   mov eax, 0
   mov edi, 0
   mov esi, nombre
   mov edx, 6
   syscall

sub eax, 1
mov ecx, eax
lea esi, [nombre]

 xor edi, edi


 convert_loop:
   xor eax, eax
   movzx eax, byte [esi]
   sub eax, '0'
   cmp eax, 10
   jae done
   imul edi, edi, 10
   add  edi, eax
   inc esi
    loop convert_loop

done:
  cmp edi, 2
  jb not_prime
  je is_prime
  mov ecx, edi
  shr ecx, 1
  mov esi, 2

check_divisibility:
   mov eax, edi
    xor edx, edx
    div esi
    cmp edx, 0
    je not_prime
    inc esi
    cmp esi, ecx
    jbe check_divisibility

is_prime:
 mov eax, 60
 mov edi, 0
 syscall

 not_prime:
mov eax, 60
mov edi, 1
syscall   