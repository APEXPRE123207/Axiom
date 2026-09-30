@echo off
title Build Axiom Desktop Standalone Executable
echo ========================================================
echo       Building Standalone AxiomDesktop.exe
echo ========================================================

cd /d "%~dp0"
pyinstaller --onefile --noconsole --icon="%~dp0logo.ico" --name="AxiomDesktop" --add-data="%~dp0logo.png;." --paths="%~dp0axiom_desktop" "%~dp0axiom_desktop\gui.py"

echo.
if exist "%~dp0dist\AxiomDesktop.exe" (
    echo [SUCCESS] Standalone AxiomDesktop.exe generated in %~dp0dist\
) else (
    echo [FAILED] Build failed. Please check the logs above.
)
pause
