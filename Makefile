.PHONY: initramfs ScuffedUtils

UNAME := $(shell uname -r)

initramfs: ScuffedUtils
ifeq ("$(wildcard initramfs/lib/modules/$(UNAME)/.*)","")
	@echo "copying modules..."
	@rm initramfs/lib/modules/* -rf
	@cp -r /lib/modules/* initramfs/lib/modules/
	@./decompress.sh
else
	@echo "modules exist, skipping"
endif
	@echo "compiling init"
	@gcc main.c -o initramfs/sbin/init -static
	@echo "generating ramdisk"
	@cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
	@zstd initramfs.cpio -f
	@echo "done!"

iso: initramfs
	@echo "generating iso"
	@cp initramfs.cpio.zst /boot/vmlinuz-linux iso/
	@mkdir -p iso/boot/grub
	@cp grub.cfg iso/boot/grub/
	@./grub.sh

ScuffedUtils:
ifeq ("$(wildcard ScuffedUtils/Makefile)","")
	@git submodule update --init --recursive
endif
	@echo "building coreutils"
	@make -C ScuffedUtils
	@cp ScuffedUtils/bin/* initramfs/bin

clean:
	@rm -rf *.cpio *.zst initramfs/sbin/init iso/* limine/ *.iso *.o
	@make -C ScuffedUtils clean
	@echo "clean!"

run: iso
	@qemu-system-x86_64 -cdrom scuffed-initrd.iso -m 4G --enable-kvm