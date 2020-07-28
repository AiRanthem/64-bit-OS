; this file will be compiled and written to the first sector of floppy as the boot sector
; fake instruction part: will not be compiled to machine code
    org 0x7c00

BaseOfStack                 equ 0x7c00
BaseOfLoader                equ 0x1000
OffsetOfLoader              equ 0x00

RootDirSectors              equ 14
SectorNumOfRootDirStart     equ 19
SectorNumOfFAT1Start        equ 1
SectorBalance               equ 17

; start of this sector, see P41
    jmp short Label_Start   ;BS_jmpBoot needs 3 bits, short jmp has 2 and nop has 1
    nop
    BS_OEMName	    db	'JoneBoot'
    BPB_BytesPerSec	dw	512
    BPB_SecPerClus	db	1
    BPB_RsvdSecCnt	dw	1
    BPB_NumFATs	    db	2
    BPB_RootEntCnt	dw	224
    BPB_TotSec16	dw	2880
    BPB_Media	    db	0xf0
    BPB_FATSz16	    dw	9
    BPB_SecPerTrk	dw	18
    BPB_NumHeads	dw	2
    BPB_HiddSec	    dd	0
    BPB_TotSec32	dd	0
    BS_DrvNum	    db	0
    BS_Reserved1	db	0
    BS_BootSig	    db	0x29
    BS_VolID	    dd	0
    BS_VolLab	    db	'boot loader'
    BS_FileSysType	db	'FAT12   '

Label_Start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax          ; 当前段兼做代码段、数据段、附加段
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

;====== search loader.bin
    mov     word    [SectorNo], SectorNumOfRootDirStart ; SectorNo 变量，初始化为根目录扇区号
Label_Search_In_Root_Dir_Begin:                         ; 循环读取扇区找Loader
    ; 循环的失败跳出判断
    cmp     word    [RootDirSizeForLoop],   0           ; RootDirSizeForLoop 变量，循环计数，初始化为 RootDirSectors，要循环这么多次每个扇区找loader
    jz      Label_No_LoaderBin                          ; 如果RootDirSectors为0，即循环次数满，所有RootDir扇区都没有找到Loader
    ; 循环主体
    dec     word    [RootDirSizeForLoop]    ; 循环计数 - 1
    ; 读一个扇区
    mov     ax,     00h
    mov     ex,     ax
    mov     bx,     8000h                   ; 设置参数ES:BX为 0:8000h 因为现在是BootLoader阶段，所以内存随便用
    mov     ax,     [SectorNo]              ; 设置参数AX为当前要读取的扇区号
    mov     cl,     1                       ; 设置参数CL位读取1个扇区
    call    Func_ReadOneSector              ; 读取一个扇区到ES:BX，00h:8000h
    ; 分析读到的扇区
    mov     si,     LoaderFileName          ; SI 指向文件名 "LOADER BIN",0 的首地址，后面LODSB用
    mov     di,     8000h                   ; ES:DI 目录页文件名某个字符的地址，这里初始化为缓存的首地址，即当前扇区第一目录页的文件名第一字符
    cld
    mov     dx,     10h                     ; 一个扇区512B，一个目录项32B，每扇区一共16个目录项，也就是10h。用DX来计数

Label_Search_For_LoaderBin:                 ; 在一个扇区内搜索每个目录页
    ; 这个扇区10h个目录项都找过了，没有找到，去下一个扇区
    cmp     dx,     0
    jz      Label_Goto_Next_Sector_In_Root_Dir
    ; 否则开始分析这个目录项的文件名
    dec     dx
    mov     cx,     11              ; 文件名的长度

Label_Cmp_Filename:
    ; 匹配成功
    cmp     cx,     0
    jz      Label_Filename_Found
    ; 否则进行匹配
    dec     cx
    lodsb                           ; 读取一个文件名字符到AL
    cmp     al,     byte    [es:di]
    jz      Label_Go_On             ; 匹配成功一个字符，去下一个
    jmp     Label_Different         ; 匹配失败
Label_Go_On:
    inc     di                      ; DI指向目录页文件名下个字符
    jmp     Label_Cmp_Filename
Label_Different:
    ; ffe0h =  11111111 1110 0000
    ; 32B = 20h =         10 0000
    ; 也就是说，每一个目录页起始就是后五位为0
    ; 将DI后五位清零就是复位之前Label_Go_On第一条指令增加的偏移量。
    and     di,     0ffe0h          ; reset DI
    add     di,     20h             ; next root page
    mov     si,     LoaderFileName  ; reset SI
    jmp     Label_Search_For_LoaderBin ; continue to next sector

Label_Goto_Next_Sector_In_Root_Dir:
    add     word    [SectorNo], 1
    jmp     Label_Search_In_Root_Dir_Begin


Label_No_LoaderBin: ; todo
Label_Filename_Found: ; todo
;====== read one sector from floppy
; :param AX: 待读取的磁盘起始扇区号
; :param CL: 读入扇区数
; :param ES:BX: 读取内容放入的目标内存首地址
Func_ReadOneSector:
	push    bp
	mov	    bp,	sp                  ; 开辟本函数的栈
	sub	    esp, 2                  ; 栈顶开辟2字节空间存储下面一行的内容
	mov     byte	[bp - 2], cl    ; 将cl（读取的扇区数）保存在刚才开辟的空间中
	push	bx                      ; 暂时保存参数，
	mov	    bl,	[BPB_SecPerTrk]     ; bl = 每磁道扇区数
	div	    bl                      ; ax / bl = al ... ah
	inc	    ah                      ; ah = ax % bl + 1 = 起始扇区号（P46公式）
	mov	    cl,	ah                  ; cl = 从1开始的扇区号高2位（软盘只有6位），INT13参数1/6
	mov	    dh,	al                  ; dh = ax / bl = 待读取的起始磁道号
	shr	    al,	1                   ; ax / bl >> 1 = 柱面号（P46公式）
	mov	    ch,	al                  ; ch = 柱面号的低八位，INT13参数2/6
	and	    dh,	1                   ; ax / bl & 0x01 = 磁头号（P46公式），INT13参数3/6
	pop	    bx                      ; 恢复参数 es:bx 缓存首地址，INT13参数4/6
	mov	    dl,	[BS_DrvNum]         ; 驱动器号，INT13参数5/6
Label_Go_On_Reading:
	mov	    ah,	2                   ; INT13功能码02h，软盘扇区读取操作
	mov	    al,	byte	[bp - 2]    ; 刚才保存的读入扇区数，INT13参数6/6
	int	    13h
	jc	    Label_Go_On_Reading     ; INT13读取成功CF=0，这条指令就是读取失败则重新读取
	add	    esp,	2               ; 销毁开头开辟的2字节空间
	pop	    bp                      ; 恢复原来的栈
	ret

;====== temp variables
RootDirSizeForLoop: dw  RootDirSectors
SectorNo:           dw  0
LoaderFileName      db  "LOADER BIN", 0 ; loader.bin在fat12中的文件名，这个0是字符串结尾符，C语言中的'\0'

;====== display message data
StartBootMessage:   db  "Hello World"

;=======	fill zero until whole sector
    times	510 - ($ - $$)	db	0
    dw	0xaa55 ; Last 2 Bytes that indicates this section is a boot program