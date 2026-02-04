bits 16
org 0x7c00

%define WIDTH 320
%define HEIGHT 192
%define TILE_POW 4
%define TILE_SIZE (1 << TILE_POW)
%define GRID_W (WIDTH / TILE_SIZE)
%define GRID_H (HEIGHT / TILE_SIZE)

%define DELAY 3000
%define BUFFER 0x8000
%define SNAKE_MAX_LEN 256

%macro get_snake_y 2
    mov %1, %2
    shl %1, 1
    sub %1, [snake_y]
%endmacro

%macro get_snake_x 2
    mov %1, %2
    shl %1, 1
    sub %1, [snake_x]
%endmacro

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7b00

    mov al, 0x13
    int 0x10

	mov bp, sp
	sub sp, 2 + 4 * SNAKE_MAX_LEN

	lea bx, [bp-2-2*SNAKE_MAX_LEN]
	mov [snake_x], bx

	lea bx, [bp-2-4*SNAKE_MAX_LEN]
	mov [snake_y], bx

	xor cx, cx
	get_snake_x si, 0
	mov [si], cx
	get_snake_y si, 0
	mov [si], cx

; Main loop {
.loop:

; Change snake direction {

; Get pressed key {
	mov ah, 1
	int 0x16
	jz .no_keys
	xor ah, ah
	int 0x16
.no_keys:
; }

	cmp al, 'w'
	mov cx, 0
	mov dx, -1
	je .l00

	cmp al, 's'
	mov cx, 0
	mov dx, 1
	je .l00

	cmp al, 'a'
	mov cx, -1
	mov dx, 0
	je .l00

	cmp al, 'd'
	mov cx, 1
	mov dx, 0
	je .l00

	jmp .l10
.l00:
	mov [dir_x], cx
	mov [dir_y], dx
.l10:
; }

; Delay {
	inc word [bp-2]
	cmp word [bp-2], DELAY
	jl .loop
; }

	xor cx, cx
	mov [bp-2], cx

	get_snake_x si, 0
	get_snake_y di, 0

; Movement {
	mov cx, [si]
	add cx, [dir_x]
	mov [si], cx

	mov dx, [di]
	add dx, [dir_y]
	mov [di], dx
; }

; HEAD_X  -> cx
; HEAD_Y  -> dx
; *HEAD_X -> si
; *HEAD_Y -> di

; Clamp {
	mov ax, [si]
	mov bx, GRID_W-1
	call clamp
	mov [si], ax

	mov ax, [di]
	mov bx, GRID_H-1
	call clamp
	mov [di], ax
; }

; Eating {
    cmp cx, [apple_x]
    jne .se_done
    cmp dx, [apple_y]
    jne .se_done

    mov ax, [apple_x]
    add al, [0x046C]
    xor ah, ah
    mov bl, GRID_W
    div bl
    xchg ah, al
    xor ah, ah
    mov [apple_x], ax

    mov ax, [apple_y]
    add al, [0x046D]
    xor ah, ah
    mov bl, GRID_H
    div bl
    xchg ah, al
    xor ah, ah
    mov [apple_y], ax
; }	

; Add snake part {
	mov ax, [snake_len]
	mov bx, ax
	inc bx	

	call copy_next

	inc word [snake_len]
; }

.se_done:
; }

; Snake parts {
	mov bx, [snake_len]
.sp_for:
	dec bx
	mov ax, bx
	dec ax

; Check intersection {
	get_snake_x si, bx
	cmp cx, [si]
	jne .sp_check

	get_snake_y si, bx
	cmp dx, [si]
	jne .sp_check

	mov [snake_len], 2
.sp_check:
; }

	call copy_next

	cmp bx, 2
	jge .sp_for
; }

; Drawing {

; Screen clear {
	mov ax, BUFFER
    mov es, ax
    xor di, di
    mov cx, WIDTH * HEIGHT
	mov al, 17
    rep stosb
; }

; Draw snake {
	xor cx, cx

.sd_for:
	get_snake_x si, cx
	mov ax, [si]
	get_snake_y si, cx
	mov bx, [si]

	push cx
	mov cx, ax
	mov dx, bx
	mov ax, 2
	call draw_tile
	pop cx

	inc cx
	cmp cx, [snake_len]
	jne .sd_for
; }

; Draw apple {
	mov cx, [apple_x]
	mov dx, [apple_y]
	mov ax, 4
	call draw_tile
; }

; Flip buffer {
	push ds
    mov ax, BUFFER
    mov ds, ax
    mov ax, 0xA000
    mov es, ax
    xor si, si
    xor di, di
    mov cx, WIDTH * HEIGHT / 2
    rep movsw
    pop ds
; }

; }
	jmp .loop
; }

draw_tile:
    mov bh, al

    shl cx, TILE_POW
    shl dx, TILE_POW

    mov di, dx
    mov ax, WIDTH
    mul di
    add ax, cx
    mov di, ax

    mov dx, TILE_SIZE

.y_loop:
    mov al, bh
    mov cx, TILE_SIZE
    rep stosb
    add di, WIDTH - TILE_SIZE
    dec dx
    jnz .y_loop
    ret

copy_next:
	push cx
	get_snake_x si, ax
	mov cx, [si]
	get_snake_x si, bx
	mov [si], cx

	get_snake_y si, ax
	mov cx, [si]
	get_snake_y si, bx
	mov [si], cx
	pop cx
	ret

clamp:
    test ax, ax
    js .neg
    cmp ax, bx
    jle .done
    mov ax, bx
    jmp .set
.neg:
    xor ax,ax
.set:
    mov word [snake_len],2
.done:
    ret

snake_x   dw 0
snake_y   dw 0
snake_len dw 1
apple_x   dw 0
apple_y   dw 0
dir_x     dw 0
dir_y     dw 0

times 510 - ($ - $$) db 0
dw 0xaa55
