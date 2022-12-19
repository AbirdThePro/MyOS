[BITS 16]
[ORG 0x7C00]

boot:

mov word [0x7E00], 0 ; make sure error check zone is cleared

mov [disk], dl ; save drive number

; set up stack
cli
mov ax, 0x2000
mov ss, ax
mov sp, 0x1000
mov bp, sp
sti

; enable A20 line
mov ax, 0x2401
int 0x15

; set VGA text mode
mov ah, 0x00
mov al, 0x03
int 0x10

; prints "Booting..."
mov si, startup_msg
call print

; resets the disk system
mov ah, 0x00
mov dl, [disk]
int 0x13

; reads kernel from disk and copies it to memory, starting at 0x7E00
mov ah, 0x02
mov al, 0x02
mov bx, 0x0000
mov es, bx
mov bx, 0x7E00
mov ch, 0
mov cl, 2
mov dh, 0
mov dl, [disk]
int 0x13

; checks if the boot succeeded (some bytes are set to a specific value)
mov word ax, [0x7E00]
cmp ax, 1100110011110000b
jne bootError

; prints message if boot succeeded
mov si, ready_msg
call print

; disables interrupts
cli
; keeps device locked until key is pressed
mov ah, 0x00
unlock:
	int 0x16
	cmp al, 0
	je unlock
sti

; jumps to kernel
jmp [es:bx+2]

; code jumps here if boot failed
bootError:

; prints error message
mov si, boot_error_msg
call print

; disables interrupts and halts the processor
cli
hlt

; prints text
print:
	mov ah, 0x0E
.loop:
	lodsb
	cmp al, 0
	je .end
	int 0x10
	jmp .loop
.end:
	ret

; messages displayed during boot process
startup_msg: db "Booting...", 10, 13, 0
ready_msg: db "OS ready. Press any key to unlock. ", 0
boot_error_msg:
	db 10, 13, "There was an error while loading the kernel."
	db 10, 13, "Please reboot the machine.", 0

; stores disk number
disk: db 0

; fills with null characters up to 0x7DED
times 510-($-$$) db 0
; boot signature so BIOS executes bootloader
dw 0xAA55
