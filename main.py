# executes all commands to compile and run operating system

from os import system

# gets bootloader binary
with open("boot.bin", "rb") as file:
    bootloader_binary = file.read()

# gets kernel binary
with open("kernel.bin", "rb") as file:
    kernel_binary = file.read()

# concatenates bootloader and kernel and creates final binary
with open("os.bin", "wb") as os:
    os.write(bootloader_binary + kernel_binary)
