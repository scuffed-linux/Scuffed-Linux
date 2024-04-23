grub=NONE
if ( command -v grub-mkrescue > /dev/null ); then
    grub=grub
fi
if ( command -v grub2-mkrescue > /dev/null ); then
    grub=grub2
fi
mkdir -p iso/EFI/BOOT

${grub}-mkstandalone -O x86_64-efi \
    --modules="efi_gop efi_uga video_bochs video_cirrus gfxterm gettext png" \
    -d /usr/lib/grub/x86_64-efi \
    --themes="" \
    --disable-shim-lock \
    -o "iso/EFI/BOOT/BOOTx64.EFI" "iso/boot/grub/grub.cfg"
${grub}-mkrescue -o scuffed-initrd.iso iso