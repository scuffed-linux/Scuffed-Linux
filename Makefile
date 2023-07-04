.PHONY: initramfs seshutils

initramfs: seshutils
	gcc main.c -o initramfs/sbin/init -static
	cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
	zstd initramfs.cpio -f

iso: initramfs
	cp initramfs.cpio.zst linux/arch/x86_64/boot/bzImage iso/
	mkdir -p iso/boot/grub
	cp grub.cfg iso/boot/grub/
	./grub.sh

seshutils:
	make -C seshutils
	cp seshutils/bin/* initramfs/bin

clean:
	rm -rf *.cpio *.zst initramfs/sbin/init iso/* limine/ *.iso *.o initramfs/lib/modules/*
	make -C seshutils clean

run: clean initramfs
	qemu-system-x86_64 -kernel linux/arch/x86_64/boot/bzImage -initrd initramfs.cpio.zst -m 4G --enable-kvm

kernel:
	cp config linux/.config
	make -C linux