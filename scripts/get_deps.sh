#!/bin/sh

# Limine 
if [ ! -d "limine" ]; then
    git clone https://github.com/limine-bootloader/limine.git --branch=v6.x-branch-binary --depth=1 --recurse-submodules
    cp limine/limine.h kernel/src/limine.h
fi