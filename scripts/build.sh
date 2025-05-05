#!/usr/bin/bash
set -euo pipefail

ARCH="riscv64"

# Step 1: Build the kernel
echo "Building the kernel for architecture $ARCH..."
cd kernel
ARCH=$ARCH sh build.sh
cd ..

# Step 2: Clean and prepare ISO directory structure
echo "Preparing the ISO directory..."
rm -rf iso_root
mkdir -p iso_root/boot
mkdir -p iso_root/boot/limine
mkdir -p iso_root/EFI/BOOT

# Step 3: Check if the required files exist and copy them
echo "Copying kernel to iso_root/boot/"
if [ ! -f "kernel/bin-$ARCH/kernel" ]; then
    echo "Error: Kernel not found!"
    exit 1
fi
cp -v kernel/bin-$ARCH/kernel iso_root/boot/

echo "Copying limine.conf to iso_root/boot/limine/"
if [ ! -f "config/limine.conf" ]; then
    echo "Error: limine.conf not found!"
    exit 1
fi
cp -v config/limine.conf iso_root/boot/limine/

echo "Copying limine-uefi-cd.bin to iso_root/boot/limine/"
if [ ! -f "limine/limine-uefi-cd.bin" ]; then
    echo "Error: limine-uefi-cd.bin not found!"
    exit 1
fi
cp -v limine/limine-uefi-cd.bin iso_root/boot/limine/

echo "Copying BOOTRISCV64.EFI to iso_root/EFI/BOOT/"
if [ ! -f "limine/BOOTRISCV64.EFI" ]; then
    echo "Error: BOOTRISCV64.EFI not found!"
    exit 1
fi
cp -v limine/BOOTRISCV64.EFI iso_root/EFI/BOOT/

# Step 4: Create the bootable ISO
echo "Creating the bootable ISO..."
xorriso -as mkisofs -R -r -J \
    -hfsplus -apm-block-size 2048 \
    --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    iso_root -o os.iso

echo "ISO creation complete: os.iso"
