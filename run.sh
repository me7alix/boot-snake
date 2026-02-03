nasm -fbin -o snake.bin ./snake.asm
qemu-system-i386 -drive file=snake.bin,format=raw,if=floppy
