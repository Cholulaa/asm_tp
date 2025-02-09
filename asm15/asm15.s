section .data
    tampon: times 64 db 0

section .text
global _start

%define O_RDONLY 0
%define SYS_open 2
%define SYS_read 0
%define SYS_close 3
%define SYS_exit 60

_start:
    mov r8, [rsp]
    cmp r8, 2
    jl e15
    mov rdi, [rsp+16]
    mov rax, SYS_open
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    cmp rax, 0
    js e15
    mov rbx, rax
    xor rax, rax
    mov rdi, rbx
    mov rsi, tampon
    mov rdx, 64
    syscall
    cmp rax, 20
    jl ce15
    mov rax, SYS_close
    mov rdi, rbx
    syscall
    mov al, [tampon]
    cmp al, 0x7F
    jne ne15
    mov al, [tampon+1]
    cmp al, 'E'
    jne ne15
    mov al, [tampon+2]
    cmp al, 'L'
    jne ne15
    mov al, [tampon+3]
    cmp al, 'F'
    jne ne15
    mov al, [tampon+4]
    cmp al, 2
    jne ne15
    xor rax, rax
    mov al, [tampon+18]
    mov ah, [tampon+19]
    cmp ax, 0x003E
    jne ne15
    mov rax, SYS_exit
    xor rdi, rdi
    syscall
ce15:
    mov rax, SYS_close
    mov rdi, rbx
    syscall
e15:
    mov rax, SYS_exit
    mov rdi, 1
    syscall
ne15:
    mov rax, SYS_exit
    mov rdi, 1
    syscall
 