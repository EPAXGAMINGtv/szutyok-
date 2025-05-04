#!/bin/sh
#TODO: other architectures
qemu-system-riscv64 \
	-M virt \
	-cpu rv64 \
	-device ramfb \
	-device qemu-xhci \
	-device usb-kbd \
	-device usb-mouse \
	-drive if=pflash,unit=0,format=raw,file=ovmf/ovmf-code-riscv64.fd,readonly=on \
	-cdrom os.iso