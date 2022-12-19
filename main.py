# executes all commands to compile and run operating system

from os import system

# compiles assembly files
system("nasm -f bin boot.asm -o boot.bin")
system("nasm -f bin kernel.asm -o kernel.bin")

# gets bootloader binary
with open("boot.bin", "rb") as file:
    bootloader_binary = file.read()

# gets kernel binary
with open("kernel.bin", "rb") as file:
    kernel_binary = file.read()

# concatenates bootloader and kernel and creates final binary
with open("os.bin", "wb") as os:
    os.write(bootloader_binary + kernel_binary)

# uses QEMU to emulate operating system
system("qemu-system-i386 -drive format=raw,file=os.bin")
