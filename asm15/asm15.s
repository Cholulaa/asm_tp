section .data
buffer: times 64 db 0

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
    jl e
    mov rdi, [rsp+16]
    mov rax, SYS_open
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    cmp rax, 0
    js e
    mov rbx, rax
    xor rax, rax
    mov rdi, rbx
    mov rsi, buffer
    mov rdx, 64
    syscall
    cmp rax, 20
    jl ce
    mov rax, SYS_close
    mov rdi, rbx
    syscall
    mov al, [buffer]
    cmp al, 0x7F
    jne ne
    mov al, [buffer+1]
    cmp al, 'E'
    jne ne
    mov al, [buffer+2]
    cmp al, 'L'
    jne ne
    mov al, [buffer+3]
    cmp al, 'F'
    jne ne
    mov al, [buffer+4]
    cmp al, 2
    jne ne
    xor rax, rax
    mov al, [buffer+18]
    mov ah, [buffer+19]
    cmp ax, 0x003E
    jne ne
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

ce:
    mov rax, SYS_close
    mov rdi, rbx
    syscall
e:
    mov rax, SYS_exit
    mov rdi, 1
    syscall

ne:
    mov rax, SYS_exit
    mov rdi, 1
    syscall
