@echo off
setlocal enabledelayedexpansion

rem Setze das Quellverzeichnis
set "srcdir=%~dp0"
if "%srcdir%"=="" set "srcdir=."

rem Wechsle in das Quellverzeichnis
cd /d "%srcdir%"

rem Funktion zum Klonen eines Repos und Wechseln zu einem bestimmten Commit
call :clone_repo_commit "https://codeberg.org/osdev/freestnd-c-hdrs-0bsd.git" "freestnd-c-hdrs" "a87c192f3eb66b0806740dc67325f9ad23fc2d0b"
call :clone_repo_commit "https://codeberg.org/osdev/cc-runtime.git" "src/cc-runtime" "b4d3b970b2f6e7d08360c66eea8314e8dd901490"

pause
exit /b

rem Funktion zum Klonen eines Repos und Checkout eines Commits
:clone_repo_commit
set "repo_url=%1"
set "repo_dir=%2"
set "commit_hash=%3"

rem Überprüfen, ob das Verzeichnis ein Git-Repository ist
if exist "%repo_dir%\.git" (
    pushd "%repo_dir%"
    git reset --hard
    git clean -fd
    git checkout %commit_hash% || (
        rd /s /q "%repo_dir%"
    )
    popd
) else (
    if exist "%repo_dir%" (
        echo error: "%repo_dir%" is not a Git repository
        exit /b 1
    )
)

rem Wenn das Repository nicht existiert, klone es
if not exist "%repo_dir%" (
    git clone %repo_url% "%repo_dir%"
    pushd "%repo_dir%"
    git checkout %commit_hash% || (
        rd /s /q "%repo_dir%"
        exit /b 1
    )
    popd
)

exit /b
