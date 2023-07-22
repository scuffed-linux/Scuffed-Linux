.PHONY: initramfs ScuffedUtils

initramfs: ScuffedUtils
	cp -r /lib/modules/* initramfs/lib/modules/
	./decompress.sh
	gcc main.c -o initramfs/sbin/init -static
	cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
	zstd initramfs.cpio -f

iso: initramfs
	cp initramfs.cpio.zst /boot/vmlinuz-linux iso/
	mkdir -p iso/boot/grub
	cp grub.cfg iso/boot/grub/
	./grub.sh

ScuffedUtils:
	make -C ScuffedUtils
	cp ScuffedUtils/bin/* initramfs/bin

clean:
	rm -rf *.cpio *.zst initramfs/sbin/init iso/* limine/ *.iso *.o initramfs/lib/modules/*
	make -C ScuffedUtils clean

run: clean initramfs
	qemu-system-x86_64 -kernel /boot/vmlinuz-linux -initrd initramfs.cpio.zst -m 4G --enable-kvm

kernel:
	cp config linux/.config
	make -C linux
