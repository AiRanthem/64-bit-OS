# 将编译好的boot程序写入软盘镜像。这个过程其实就是格式化软盘为FAT12
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
# 挂载镜像到宿主机文件系统
mount boot.img /media -t vfat -o loop
# 将loader文件拷贝到软盘中。我们的文件系统会自动设置软盘的FAT12目录、分配簇
cp loader.bin /media
sync
umount /media