    org 0x7c00

BaseOfStack equ 0x7c00

Label_Start:

    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

;====== clear screen
    mov ax, 0600h
    mov bx, 0700h ; no use here
    mov cx, 0     ; no use here
    mov dx, 0184fh; no use here
    int 10h

;====== set focus
    mov ax, 0200h
    mov bx, 000fh
    mov dx, 0000h
    int 10h

;====== display on screen : Start Booting......
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0000h
    mov cx, 11

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, StartBootMessage
    int 10h

;====== reset floppy
    xor ah, ah
    xor dl, dl
    int 13h

    jmp $

StartBootMessage:   db  "Hello World"

;=======	fill zero until whole sector
    times	510 - ($ - $$)	db	0
    dw	0xaa55 ; Last 2 Bytes that indicates this section is a boot program