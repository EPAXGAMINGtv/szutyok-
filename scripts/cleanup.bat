@echo off
rem Entferne das Verzeichnis "iso_root"
rd /s /q "iso_root"

rem Entferne das Verzeichnis "limine"
rd /s /q "limine"

rem Entferne das Verzeichnis "ovmf"
rd /s /q "ovmf"

rem Entferne alle Dateien im Verzeichnis "kernel/bin-*"
del /f /q "kernel\bin-*"

rem Entferne alle Dateien im Verzeichnis "kernel/obj-*"
del /f /q "kernel\obj-*"

rem Entferne das Verzeichnis "kernel/freestnd-c-hdrs"
rd /s /q "kernel\freestnd-c-hdrs"

rem Entferne das Verzeichnis "kernel/src/cc-runtime"
rd /s /q "kernel\src\cc-runtime"

rem Entferne die Datei "kernel/src/limine.h"
del /f /q "kernel\src\limine.h"

echo Alle angegebenen Verzeichnisse und Dateien wurden entfernt.
pause
