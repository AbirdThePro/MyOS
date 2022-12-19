nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin

python main.py

qemu-system-i386 -drive format=raw,file=os.bin
