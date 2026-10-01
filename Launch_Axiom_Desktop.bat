@echo off
title Axiom Desktop Receiver
where python >nul 2>nul
if %errorlevel% equ 0 (
    cd /d "%~dp0axiom_desktop"
    python gui.py
    exit /b
)
if exist "%~dp0dist\AxiomDesktop.exe" (
    start "" "%~dp0dist\AxiomDesktop.exe"
    exit /b
)
pause
