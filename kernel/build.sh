#!/usr/bin/bash

export ARCH="riscv64"
OUTPUT="kernel"
export CC=/usr/bin/clang
CFLAGS="-g -O2 -pipe"
CPPFLAGS=""
LDFLAGS=""
SRC_DIR="src"
OBJ_DIR="obj-${ARCH}"
BIN_DIR="bin-${ARCH}"
OUTPUT_BIN="${BIN_DIR}/${OUTPUT}"

SUPPORTED_ARCHS="aarch64 loongarch64 riscv64 x86_64"
if ! echo "$SUPPORTED_ARCHS" | grep -q "\b${ARCH}\b"; then
    echo "Architecture ${ARCH} not supported"
    exit 1
fi


if [[ "${1:-}" != "clean" && "${1:-}" != "distclean" ]]; then
    if [[ ! -d freestnd-c-hdrs || ! -d src/cc-runtime || ! -f src/limine.h ]]; then
        echo "Please run the ./get-deps script first"
        exit 1
    fi
fi

if ${CC} --version 2>/dev/null | grep -q clang; then
    CC_IS_CLANG=1
else
    CC_IS_CLANG=0
fi

CFLAGS+=" -Wall -Wextra -std=gnu11 -nostdinc -ffreestanding"
CFLAGS+=" -fno-stack-protector -fno-stack-check -fno-PIC"
CFLAGS+=" -ffunction-sections -fdata-sections"

CPPFLAGS+=" -I src -isystem freestnd-c-hdrs"
CPPFLAGS+=" -DLIMINE_API_REVISION=3"

NASMFLAGS=""
if [[ "${ARCH}" == "x86_64" ]]; then
    [[ "$CC_IS_CLANG" == "1" ]] && CC+=" -target x86_64-unknown-none"
    CFLAGS+=" -m64 -march=x86-64 -mno-80387 -mno-mmx -mno-sse -mno-sse2 -mno-red-zone -mcmodel=kernel"
    LDFLAGS+=" -Wl,-m,elf_x86_64"
    NASMFLAGS="-F dwarf -g -Wall -f elf64"
elif [[ "${ARCH}" == "aarch64" ]]; then
    [[ "$CC_IS_CLANG" == "1" ]] && CC+=" -target aarch64-unknown-none"
    CFLAGS+=" -mgeneral-regs-only"
    LDFLAGS+=" -Wl,-m,aarch64elf"
elif [[ "${ARCH}" == "riscv64" ]]; then
    [[ "$CC_IS_CLANG" == "1" ]] && {
        CC+=" -target riscv64-unknown-none"
        CFLAGS+=" -march=rv64imac"
    } || {
        CFLAGS+=" -march=rv64imac_zicsr_zifencei"
    }
    CFLAGS+=" -mabi=lp64 -mno-relax"
    LDFLAGS+=" -Wl,-m,elf64lriscv -Wl,--no-relax"
elif [[ "${ARCH}" == "loongarch64" ]]; then
    [[ "$CC_IS_CLANG" == "1" ]] && CC+=" -target loongarch64-unknown-none"
    CFLAGS+=" -march=loongarch64 -mabi=lp64s"
    LDFLAGS+=" -Wl,-m,elf64loongarch -Wl,--no-relax"
fi

LDFLAGS+=" -Wl,--build-id=none -nostdlib -static -z max-page-size=0x1000 -Wl,--gc-sections"
LDFLAGS+=" -T linker-${ARCH}.ld"

SRCFILES=$(cd src && find -L . -type f | sort)
CFILES=()
ASFILES=()
NASMFILES=()

for file in ${SRCFILES}; do
    case "$file" in
        *.c) CFILES+=("$file") ;;
        *.S) ASFILES+=("$file") ;;
        *.asm) [[ "$ARCH" == "x86_64" ]] && NASMFILES+=("$file") ;;
    esac
done

mkdir -p "$OBJ_DIR"

for file in "${CFILES[@]}"; do
    src="$SRC_DIR/${file}"
    obj="${OBJ_DIR}/${file%.c}.c.o"
    mkdir -p "$(dirname "$obj")"
    echo "CC $src -> $obj"
    $CC $CFLAGS $CPPFLAGS -c "$src" -o "$obj"
done

for file in "${ASFILES[@]}"; do
    src="$SRC_DIR/${file}"
    obj="${OBJ_DIR}/${file%.S}.S.o"
    mkdir -p "$(dirname "$obj")"
    echo "AS $src -> $obj"
    $CC $CFLAGS $CPPFLAGS -c "$src" -o "$obj"
done

if [[ "$ARCH" == "x86_64" ]]; then
    for file in "${NASMFILES[@]}"; do
        src="$SRC_DIR/${file}"
        obj="${OBJ_DIR}/${file%.asm}.asm.o"
        mkdir -p "$(dirname "$obj")"
        echo "NASM $src -> $obj"
        nasm $NASMFLAGS "$src" -o "$obj"
    done
fi

mkdir -p "$BIN_DIR"
echo "LD -> ${OUTPUT_BIN}"
$CC $CFLAGS $LDFLAGS $(find "$OBJ_DIR" -name '*.o') -o "$OUTPUT_BIN"

echo "Build complete: $OUTPUT_BIN"
