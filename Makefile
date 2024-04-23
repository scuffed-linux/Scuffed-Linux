.PHONY: initramfs ScuffedUtils

UNAME := $(shell uname -r)

initramfs: ScuffedUtils
ifeq ("$(wildcard initramfs/lib/modules/$(UNAME)/.*)","")
	@echo "copying modules..."
	@rm initramfs/lib/modules/* -rf
	@cp -r kernel/usr/lib/modules/* initramfs/lib/modules/
	@echo "extracting modules..."
	@./decompress.sh
else
	@echo "modules exist, skipping"
endif
	@echo "compiling init..."
	@gcc main.c -o initramfs/sbin/init -static
	@echo "generating ramdisk..."
	@cd initramfs && find . | cpio -o -H newc > ../initramfs.cpio
	@zstd initramfs.cpio -f > /dev/null
	@echo "done!"

iso: initramfs
	@mkdir -p iso
	@echo "generating iso..."
	@cp initramfs.cpio.zst kernel/usr/lib/modules/6.8.5-arch1-1/vmlinuz iso/
	@mkdir -p iso/boot/grub
	@cp grub.cfg iso/boot/grub/
	@./grub.sh

kernel:
ifeq ("$(wildcard kernel/.PKGINFO)","")
	wget https://archlinux.org/packages/core-testing/x86_64/linux/download/ -O linux.tar.zstd
	mkdir -p kernel
	tar -xf linux.tar.zstd -C kernel/
endif


ScuffedUtils:
ifeq ("$(wildcard ScuffedUtils/Makefile)","")
	@git submodule update --init --recursive
endif
	@echo "building coreutils..."
	@make -C ScuffedUtils
	@cp ScuffedUtils/bin/* initramfs/bin

clean:
	@rm -rf *.cpio *.zst initramfs/sbin/init iso/* limine/ *.iso *.o initramfs/lib/modules/* initramfs/bin/*
	@make -C ScuffedUtils clean
	@echo "clean!"
	
run: iso
	@qemu-system-x86_64 -cdrom scuffed-initrd.iso -m 4G -bios /usr/share/OVMF/OVMF_CODE.fd