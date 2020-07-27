# BootLoader
本章主要复习汇编语言。以下内容整理自网络与我的汇编语言课程笔记

[boot.asm](../../source/3-1/boot.asm)

Boot程序运行时，BIOS会初始化寄存器：CS=0x0000, IP=0x7c00

汇编代码中，一行就是一条代码段指令，大小是一字节

## Intel ASM 伪指令
|   指令    |                           作用                            |                      示例                       |
|:-------:|:-------------------------------------------------------:|:---------------------------------------------:|
|  `org`  |              Origin 指明程序的起始地址，不写的话就是0x0000              |                  org 0x7c00                   |
|  `equ`  |              等价。将左边的式子等价位右面的值，一般用来定义常亮和助记符              |            BaseOfStack equ 0x7c00             |
|  `db`   | 定义变量为字节。在当前行所在的代码段位置开始放置 db 后的内容，如果前面有别名（flag）则可以通过别名访问 |       StartBootMessage: db "Start Boot"       |
|  `dw`   |                         定义变量为字                          |                                               |
|  `dd`   |                         定义变量为双字                         |                                               |
|  `dq`   |                         定义变量为四字                         |                                               |
|  `dt`   |                         定义变量为十字                         |                                               |
|   `$`   |                     当前行行号（代码段内的偏移量）                     |                                               |
|  `$$`   |                         当前段的首地址                         |                                               |
| `times` |                       重复若干次后面的内容                        | times	510 - ($ - $$)	db	0 ; 代码段中当前指令往后到510填充0 |

## 寄存器
>部分摘抄自 [这篇博客](https://blog.csdn.net/u014287775/article/details/76572496)

`AX`――累加器（Accumulator），使用频度最高

`BX`――基址寄存器（Base Register），常存放存储器地址

`CX`――计数器（Count Register），常作为计数器

`DX`――数据寄存器（Data Register），存放数据

`SI`――源变址寄存器（Source Index），常保存存储单元地址

`DI`――目的变址寄存器（Destination Index），常保存存储单元地址

`BP`――基址指针寄存器（Base Pointer），表示堆栈区域中的基地址

`SP`――堆栈指针寄存器（Stack Pointer），指示堆栈区域的栈顶地址

`IP`――指令指针寄存器（Instruction Pointer），指示要执行指令所在存储单元的地址。IP寄存器是一个专用寄存器。

`DS`――数据段寄存器，数据段基址

`CS`――代码段寄存器，代码段基址

`SS`――堆栈段寄存器，堆栈段基址

`ES`――附加段寄存器

最早8位机只有a，b等寄存器。

到16位机a，b扩展到16位以后，就把16位叫ax，bx。 高8位叫ah，bh，低8位叫al，bl，其实还是a，b。

到了32位机a，b扩展到32位，又改成eax，ebx。

当然ax，bx继续代表低16位，ah，al，bh，bl，a，b继续维持以前的意义不变。

### MOV的规则
1. CS、IP的值不可以作为目标操作数；
2. dest、src不可以同时作为存储器操作数出现；
3. 段寄存器不能相互转送；
4. 不能把立即数送入段寄存器。

## BIOS中断服务程序
调用时中断服务，需要向`AH`传入主功能编号，再向其他寄存器传入参数

`INT 10h` 屏幕相关中断服务 详解在书本 **P34**

`INT 13h` 磁盘相关中断服务 书本 **P35**

## 使用nasm编译汇编代码
```shell script
nasm <asm file> -o <object file>
nasm boot.asm -o boot.bin
```

## 在bochs中运行Boot程序
```shell script
# 将编译好的boot程序写入软盘镜像
dd if=boot.bin of=../../resources/boot.img bs=512 count=1 conv=notrunc
# 启动bochs虚拟机
bochs -f resources/bochsrc
```