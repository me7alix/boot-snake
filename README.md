# Boot Snake
<img width="812" height="485" alt="image" src="https://github.com/user-attachments/assets/7a43a1be-2d2c-4c80-8f90-f6589b58eaf3" />

The goal is to make a game in assembly that fits into 512 bytes of bootloader and works without OS

## Dependencies
- nasm
- qemu

## Build and run
```
# run the game in qemu
make run
# or run it in a browser using jsdos
make jsdos
python3 -m http.server 8000
```
