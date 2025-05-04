#!/bin/sh
# Limine 
git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1 --recurse-submodules
cp limine/limine.h kernel/src/limine.h
make -C limine

sh kernel/get-deps.sh

mkdir -p ovmf
curl -Lo ovmf/ovmf-code-riscv64.fd https://github.com/osdev0/edk2-ovmf-nightly/releases/latest/download/ovmf-code-riscv64.fd
dd if=/dev/zero of=ovmf/ovmf-code-riscv64.fd bs=1 count=0 seek=33554432 2>/dev/null