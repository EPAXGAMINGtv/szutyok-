@echo off
setlocal

rem Prüfen, ob das Verzeichnis "limine" existiert
if not exist limine (
    git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1 --recurse-submodules
    if errorlevel 1 (
        echo Fehler beim Klonen von limine
        exit /b 1
    )
)

rem limine.h kopieren
copy limine\limine.h kernel\src\limine.h >nul

rem Anderes Skript aus kernel\get-deps.bat aufrufen
call kernel\get-deps.bat

rem ovmf-Verzeichnis erstellen
mkdir ovmf >nul 2>nul

rem ovmf-Datei herunterladen
curl -L -o ovmf\ovmf-code-riscv64.fd https://github.com/osdev0/edk2-ovmf-nightly/releases/latest/download/ovmf-code-riscv64.fd

rem ovmf-Datei auf 32 MiB aufblasen
fsutil file createnew ovmf\ovmf-code-riscv64.fd 33554432

endlocal
