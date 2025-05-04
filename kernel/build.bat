@echo off
setlocal enabledelayedexpansion

rem Konfiguration
set "OUTPUT=kernel"
set "CC=clang"
set "CFLAGS=-g -O2 -pipe"
set "CPPFLAGS="
set "LDFLAGS="
set "SRC_DIR=src"
set "OBJ_DIR=obj-%ARCH%"
set "BIN_DIR=bin-%ARCH%"
set "OUTPUT_BIN=%BIN_DIR%\%OUTPUT%"

rem Unterstützte Architekturen
set "SUPPORTED_ARCHS=aarch64 loongarch64 riscv64 x86_64"
echo %SUPPORTED_ARCHS% | findstr /i "%ARCH%" >nul
if %errorlevel% neq 0 (
    echo Architecture %ARCH% not supported
    exit /b 1
)

rem Abhängigkeiten prüfen
if not "%1"=="clean" if not "%1"=="distclean" (
    if not exist "freestnd-c-hdrs" (
        echo Please run the ./get-deps script first
        exit /b 1
    )
    if not exist "src\cc-runtime" (
        echo Please run the ./get-deps script first
        exit /b 1
    )
    if not exist "src\limine.h" (
        echo Please run the ./get-deps script first
        exit /b 1
    )
)

rem Überprüfen, ob der Compiler Clang ist
clang --version >nul 2>&1
if %errorlevel% equ 0 (
    set "CC_IS_CLANG=1"
) else (
    set "CC_IS_CLANG=0"
)

rem Interne CFLAGS hinzufügen
set CFLAGS=%CFLAGS% -Wall -Wextra -std=gnu11 -nostdinc -ffreestanding
set CFLAGS=%CFLAGS% -fno-stack-protector -fno-stack-check -fno-PIC
set CFLAGS=%CFLAGS% -ffunction-sections -fdata-sections

rem Interne CPPFLAGS hinzufügen
set CPPFLAGS=%CPPFLAGS% -I src -isystem freestnd-c-hdrs
set CPPFLAGS=%CPPFLAGS% -DLIMINE_API_REVISION=3

rem Architektur-spezifische Einstellungen
set NASMFLAGS=
if "%ARCH%"=="x86_64" (
    if %CC_IS_CLANG%==1 set CC=%CC% -target x86_64-unknown-none
    set CFLAGS=%CFLAGS% -m64 -march=x86-64 -mno-80387 -mno-mmx -mno-sse -mno-sse2 -mno-red-zone -mcmodel=kernel
    set LDFLAGS=%LDFLAGS% -Wl,-m,elf_x86_64
    set NASMFLAGS=-F dwarf -g -Wall -f elf64
) else if "%ARCH%"=="aarch64" (
    if %CC_IS_CLANG%==1 set CC=%CC% -target aarch64-unknown-none
    set CFLAGS=%CFLAGS% -mgeneral-regs-only
    set LDFLAGS=%LDFLAGS% -Wl,-m,aarch64elf
) else if "%ARCH%"=="riscv64" (
    if %CC_IS_CLANG%==1 (
        set CC=%CC% -target riscv64-unknown-none
        set CFLAGS=%CFLAGS% -march=rv64imac
    ) else (
        set CFLAGS=%CFLAGS% -march=rv64imac_zicsr_zifencei
    )
    set CFLAGS=%CFLAGS% -mabi=lp64 -mno-relax
    set LDFLAGS=%LDFLAGS% -Wl,-m,elf64lriscv -Wl,--no-relax
) else if "%ARCH%"=="loongarch64" (
    if %CC_IS_CLANG%==1 set CC=%CC% -target loongarch64-unknown-none
    set CFLAGS=%CFLAGS% -march=loongarch64 -mabi=lp64s
    set LDFLAGS=%LDFLAGS% -Wl,-m,elf64loongarch -Wl,--no-relax
)

set LDFLAGS=%LDFLAGS% -Wl,--build-id=none -nostdlib -static -z max-page-size=0x1000 -Wl,--gc-sections
set LDFLAGS=%LDFLAGS% -T linker-%ARCH%.ld

rem Quellcode-Dateien
rem Liste der Quell-Dateien (nur .c, .S und .asm)
set SRCFILES=
for /r %SRC_DIR% %%f in (*.c) do (
    set SRCFILES=!SRCFILES! "%%f"
)

rem Objekt-Dateien
set CFILES=
set ASFILES=
set NASMFILES=

for %%f in (!SRCFILES!) do (
    set file=%%f
    if "!file:~-2!"=="c" (
        set CFILES=!CFILES! "%%f"
    ) else if "!file:~-2!"=="S" (
        set ASFILES=!ASFILES! "%%f"
    ) else if "!file:~-3!"=="asm" if "%ARCH%"=="x86_64" (
        set NASMFILES=!NASMFILES! "%%f"
    )
)

rem Erstelle Objekt-Verzeichnisse
mkdir "%OBJ_DIR%"

rem Kompiliere .c-Dateien
for %%f in (%CFILES%) do (
    set src=%%f
    set obj=%OBJ_DIR%\%%~nf.o
    mkdir "%OBJ_DIR%\%%~dpf"
    echo CC %src% -> %obj%
    %CC% %CFLAGS% %CPPFLAGS% -c "%src%" -o "%obj%"
)

rem Kompiliere .S-Dateien
for %%f in (%ASFILES%) do (
    set src=%%f
    set obj=%OBJ_DIR%\%%~nf.o
    mkdir "%OBJ_DIR%\%%~dpf"
    echo AS %src% -> %obj%
    %CC% %CFLAGS% %CPPFLAGS% -c "%src%" -o "%obj%"
)

rem Kompiliere .asm-Dateien (nur für x86_64)
if "%ARCH%"=="x86_64" (
    for %%f in (%NASMFILES%) do (
        set src=%%f
        set obj=%OBJ_DIR%\%%~nf.o
        mkdir "%OBJ_DIR%\%%~dpf"
        echo NASM %src% -> %obj%
        nasm %NASMFLAGS% "%src%" -o "%obj%"
    )
)

rem Linke die Objekt-Dateien
mkdir "%BIN_DIR%"
echo LD -> %OUTPUT_BIN%
%CC% %CFLAGS% %LDFLAGS% %OBJ_DIR%\*.o -o "%OUTPUT_BIN%"

echo Build complete: %OUTPUT_BIN%
pause
