@echo off
title Axiom Desktop Receiver
if exist "%~dp0dist\AxiomDesktop.exe" (
    start "" "%~dp0dist\AxiomDesktop.exe"
    exit /b
)
cd /d "%~dp0axiom_desktop"
python gui.py
pause
