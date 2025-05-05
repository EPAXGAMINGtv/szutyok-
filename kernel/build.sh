#!/bin/bash

# Set architecture and output
export ARCH="riscv64"
bOUTPUT="kernel"
export CC=/usr/bin/clang

# Compilation flags and directories
CFLAGS="-g -O2 -pipe"
CPPFLAGS=""
LDFLAGS=""
SRC_DIR="src"
OBJ_DIR="obj-${ARCH}"
BIN_DIR="bin-${ARCH}"
OUTPUT_BIN="${BIN_DIR}/${OUTPUT}"

# Supported architectures
SUPPORTED_ARCHS="aarch64 loongarch64 riscv64 x86_64"
echo "$SUPPORTED_ARCHS" | grep -wq "$ARCH" || { echo "Architecture ${ARCH} not supported"; exit 1; }

# Determine if clang is being used
if $CC --version 2>/dev/null | grep -q clang; then
    CC_IS_CLANG=1
else
    CC_IS_CLANG=0
fi

# Set compilation flags
CFLAGS="$CFLAGS -Wall -Wextra -std=gnu11 -nostdinc -ffreestanding"
CFLAGS="$CFLAGS -fno-stack-protector -fno-stack-check -fno-PIC"
CFLAGS="$CFLAGS -ffunction-sections -fdata-sections"

CPPFLAGS="$CPPFLAGS -I src -isystem freestnd-c-hdrs"
CPPFLAGS="$CPPFLAGS -DLIMINE_API_REVISION=3"

# Setup for different architectures
case "$ARCH" in
    x86_64)
        if [ "$CC_IS_CLANG" -eq 1 ]; then
            CC="$CC -target x86_64-unknown-none"
        fi
        CFLAGS="$CFLAGS -m64 -march=x86-64 -mno-80387 -mno-mmx -mno-sse -mno-sse2 -mno-red-zone -mcmodel=kernel"
        LDFLAGS="$LDFLAGS -Wl,-m,elf_x86_64"
        NASMFLAGS="-F dwarf -g -Wall -f elf64"
        ;;
    aarch64)
        if [ "$CC_IS_CLANG" -eq 1 ]; then
            CC="$CC -target aarch64-unknown-none"
        fi
        CFLAGS="$CFLAGS -mgeneral-regs-only"
        LDFLAGS="$LDFLAGS -Wl,-m,aarch64elf"
        ;;
    riscv64)
        if [ "$CC_IS_CLANG" -eq 1 ]; then
            CC="$CC -target riscv64-unknown-none"
            CFLAGS="$CFLAGS -march=rv64imac"
        else
            CFLAGS="$CFLAGS -march=rv64imac_zicsr_zifencei"
        fi
        CFLAGS="$CFLAGS -mabi=lp64 -mno-relax"
        LDFLAGS="$LDFLAGS -Wl,-m,elf64lriscv -Wl,--no-relax"
        ;;
    loongarch64)
        if [ "$CC_IS_CLANG" -eq 1 ]; then
            CC="$CC -target loongarch64-unknown-none"
        fi
        CFLAGS="$CFLAGS -march=loongarch64 -mabi=lp64s"
        LDFLAGS="$LDFLAGS -Wl,-m,elf64loongarch -Wl,--no-relax"
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

# Finalize linker flags
LDFLAGS="$LDFLAGS -Wl,--build-id=none -nostdlib -static -z max-page-size=0x1000 -Wl,--gc-sections"
LDFLAGS="$LDFLAGS -T linker-${ARCH}.ld"

# Find all source files
SRCFILES=$(cd "$SRC_DIR" && find . -type f | sort)

# Initialize file lists
CFILES=""
ASFILES=""
NASMFILES=""

# Classify source files by type
for file in $SRCFILES; do
    case "$file" in
        *.c) CFILES="$CFILES $file" ;;  # C files
        *.S) ASFILES="$ASFILES $file" ;;  # Assembly files
        *.asm)
            if [ "$ARCH" = "x86_64" ]; then
                NASMFILES="$NASMFILES $file"  # Only add asm files if architecture is x86_64
            fi
            ;;
    esac
done

# Create object directory
mkdir -p "$OBJ_DIR"

# Compile C files
for file in $CFILES; do
    src="$SRC_DIR/$file"
    obj="${OBJ_DIR}/${file%.c}.c.o"
    mkdir -p "$(dirname "$obj")"
    echo "CC $src -> $obj"
    $CC $CFLAGS $CPPFLAGS -c "$src" -o "$obj"
done

# Compile assembly files
for file in $ASFILES; do
    src="$SRC_DIR/$file"
    obj="${OBJ_DIR}/${file%.S}.S.o"
    mkdir -p "$(dirname "$obj")"
    echo "AS $src -> $obj"
    $CC $CFLAGS $CPPFLAGS -c "$src" -o "$obj"
done

# Compile NASM files if on x86_64
if [ "$ARCH" = "x86_64" ]; then
    for file in $NASMFILES; do
        src="$SRC_DIR/$file"
        obj="${OBJ_DIR}/${file%.asm}.asm.o"
        mkdir -p "$(dirname "$obj")"
        echo "NASM $src -> $obj"
        nasm $NASMFLAGS "$src" -o "$obj"
    done
fi

# Create binary directory and link final kernel
mkdir -p "$BIN_DIR"
echo "LD -> $OUTPUT_BIN"
$CC $CFLAGS $LDFLAGS $(find "$OBJ_DIR" -name '*.o') -o "$OUTPUT_BIN"

echo "Build complete: $OUTPUT_BIN"
