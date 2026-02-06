NASM = nasm -f bin
QEMU = qemu-system-i386
JSDOS = jsdos

ASM = snake.asm
BIN = snake.bin
ZIP = bootgame.zip
IMG = $(JSDOS)/floppy.img

.PHONY: run jsdos

run: $(BIN)
	$(QEMU) -drive file=$(BIN),format=raw,if=floppy

$(BIN): $(ASM)
	$(NASM) -o $(BIN) $(ASM)

jsdos: $(BIN)
	dd if=/dev/zero of=$(IMG) bs=512 count=2880
	dd if=$(BIN) of=$(IMG) conv=notrunc
	cd $(JSDOS) && zip -r ../$(ZIP) .
