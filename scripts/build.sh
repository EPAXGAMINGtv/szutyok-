#!/bin/sh

ARCH="riscv64"

cd kernel
ARCH=$ARCH sh build.sh
cd ..

rm -rf iso_root
mkdir -p iso_root/boot
cp -v kernel/bin-$ARCH/kernel iso_root/boot/
mkdir -p iso_root/boot/limine
cp -v config/limine.conf iso_root/boot/limine/
mkdir -p iso_root/EFI/BOOT
cp -v limine/limine-uefi-cd.bin iso_root/boot/limine/
cp -v limine/BOOTRISCV64.EFI iso_root/EFI/BOOT/
xorriso -as mkisofs -R -r -J \
	-hfsplus -apm-block-size 2048 \
	--efi-boot boot/limine/limine-uefi-cd.bin \
	-efi-boot-part --efi-boot-image --protective-msdos-label \
	iso_root -o os.iso