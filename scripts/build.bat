@echo off
setlocal

set ARCH=riscv64

rem In das kernel-Verzeichnis wechseln und build.bat ausführen
pushd kernel
call build.bat
popd

rem iso_root neu erstellen
rd /s /q iso_root 2>nul
mkdir iso_root\boot
mkdir iso_root\boot\limine
mkdir iso_root\EFI\BOOT

rem Kernel kopieren
copy kernel\bin-%ARCH%\kernel iso_root\boot\ >nul

rem Limine-Konfiguration kopieren
copy config\limine.conf iso_root\boot\limine\ >nul

rem Limine UEFI Bootloader-Dateien kopieren
copy limine\limine-uefi-cd.bin iso_root\boot\limine\ >nul
copy limine\BOOTRISCV64.EFI iso_root\EFI\BOOT\ >nul

rem ISO mit xorriso erstellen
xorriso -as mkisofs -R -r -J ^
  -hfsplus -apm-block-size 2048 ^
  --efi-boot boot/limine/limine-uefi-cd.bin ^
  -efi-boot-part --efi-boot-image --protective-msdos-label ^
  iso_root -o os.iso

endlocal
