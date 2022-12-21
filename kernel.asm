[BITS 16]
[ORG 0x7E00]

; this is used to verify that the boot succeeded - if the loader reads this, it knows that the kernel was successfully copied to memory
dw 1100110011110000b

; stores disk number in new variable
mov al, [0x7DFD]
mov [disk], al

; clears screen
call clear_screen

; makes sure user types in password (1234)
passwordCheck:
	mov si, password_prompt_msg

	mov di, passwordBuffer
	mov bx, 16
	call input

	mov si, passwordBuffer
	mov di, password
	mov cx, 16
	call compare_strings

	cmp ax, 0
	jne .wrongPassword

	jmp kernel

; if entered password is wrong the code will jump here
.wrongPassword:
	call clear_screen
	mov si, incorrect_password_msg
	call print
	jmp passwordCheck

; beginning of kernel
kernel:

; clears screen
call shell_clear

; displays start message
mov si, start_msg
call print

; beginning of shell code
shell:

; clears shell
call shell_clear_command

; allows user to enter command
mov si, command_beginning_msg
mov di, command
mov bx, 64
call input

; the below code checks what the user types to see if it matches a command and executes it if it does

mov si, command
mov di, cmd_clear
mov cx, 5
call compare_strings
cmp ax, 0
je shell_clear

mov si, command
mov di, cmd_echo
mov cx, 4
call compare_strings
cmp ax, 0
je shell_echo

mov si, command
mov di, cmd_help
mov cx, 4
call compare_strings
cmp ax, 0
je shell_help

; if no command is executed display the 'Command not found' message
mov si, command_not_found_msg
call print

; continues the loop
jmp shell

; makes sure code is not executed past this point unless it is a function call
cli
hlt

; clears shell
shell_clear:
	call clear_screen
	jmp shell

; prints passed argument
shell_echo:
	mov si, command
	mov ah, 32
	call find_char
	inc ax
	mov si, ax
	call print
	call nl
	jmp shell

; displays help information
shell_help:
	mov si, help_msg
	call print
	jmp shell

 ; fills the command buffer with null characters
shell_clear_command:
	mov di, command
.loop:
	mov al, 32
	stosb
	cmp byte [di], 0
	je .end
	jmp .loop
.end:
	ret

; prints string
print:
	mov ah, 0x0E
.loop:
	lodsb
	cmp al, 0
	je .end
	cmp al, 10
	jne .not_nl
	call nl
	.not_nl:
	int 0x10
	jmp .loop
.end:
	ret

; TODO: Make it print a number
printnum:
	mov ah, 0x0E
	.loop:

; takes user input
input:
	call print
	xor cx, cx
.loop:
	cmp cx, bx
	je .end
	mov ah, 0x00
	int 0x16
	cmp al, 0
	je .loop
	cmp al, 13
	je .end
	cmp al, 8
	je .backspace
	mov ah, 0x0E
	int 0x10
	stosb
	inc cx
	jmp .back
.backspace:
		cmp cx, 0
		je .back
		dec di
		call backspace
		dec cx
.back:
		jmp .loop
.end:
	mov al, 0
	stosb
	call nl
	ret

; prints newline and resets cursor
nl:
	mov ah, 0x0E
	mov al, 10
	int 0x10
	mov al, 13
	int 0x10
	ret

; used to allow user to correct mistakes when typing commands
backspace:
	mov ah, 0x0E
	mov al, 8
	int 0x10
	mov al, 32
	int 0x10
	mov al, 8
	int 0x10
	ret

; clears screen
clear_screen:
	mov ah, 0x00
	mov al, 0x03
	int 0x10
	ret

; assembly equivalent of strcmp()
compare_strings:
	inc cx
	xor ax, ax
	.loop:
		dec cx
		cmp cx, 0
		je .end
		mov byte bh, [si]
		mov byte bl, [di]
		inc si
		inc di
		cmp bh, bl
		jne .notEqual
		cmp bh, 0
		je .end
		cmp bl, 0
		je .end
		jmp .loop
	.notEqual:
		inc ax
		jmp .loop
	.end:
		ret

; assembly equivalent of strtok()
get_token:
	call find_char
	mov di, ax
	mov al, 0
	stosb
	ret

; assembly equivalent of strchr()
find_char:
	.loop:
		lodsb
		cmp ah, al
		jne .loop
	.end:
		dec si
		mov ax, si
		ret

; reads from disk
disk_read:
	mov ah, 0x02
	mov al, 1
	mov bx, 0x0000
	mov es, bx
	mov bx, di
	mov ch, 0
	mov dh, 0
	mov dl, [0x7DFD]
	int 0x13

; stores disk number
disk: db 0

; password storage
passwordBuffer: times 16 db 0
password: db "1234", 0
passwordLen equ ($-password)-1

command:
	times 64 db 32
	db 0

; table of commands
command_table_start:
	cmd_clear: db "clear", 0
	cmd_echo: db "echo", 0
	cmd_help: db "help", 0
command_table_end:

; password messages
password_prompt_msg: db "Enter password: ", 0
incorrect_password_msg: db "Incorrect password. Try again.", 10, 13, 0

; displayed when user reaches terminal
start_msg: db "MyOS v1.0", 10
		   db "use 'help' for a list of commands", 10, 0

; command prompt messages
command_beginning_msg: db "My-OS-User1-$ ", 0
command_not_found_msg: db "Command not found.", 10, 13, 0

; displayed when user runs 'help' command
help_msg: db "MyOS v1.0", 10
		  db "Commands:", 10
		  db "----------------------------", 10
		  db "echo <string>", 10
		  db "prints message in console", 10
		  db "----------------------------", 10
		  db "clear", 10
		  db "clears console", 10
		  db "----------------------------", 10, 0

; pads with null bytes until 0x8E00
times 1024-($-$$) db 0
