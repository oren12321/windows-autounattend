@echo off
chcp 437 >nul

echo Installing NVIDIA driver...
echo.

:: Delete old setupapi log
del %windir%\INF\setupapi.dev.log 2>nul

:: Platform config / power / panel
pnputil -i -a ".\NVPCF\nvpcf.inf"

:: Platform config / ACPI / mux
pnputil -i -a ".\PPC\nvppc.inf"

:: Core display driver
pnputil -i -a ".\Display.Driver\nvamsi.inf"

:: HDMI/DP audio
pnputil -i -a ".\HDAudio\nvhda.inf"

:: Virtual audio for recording
pnputil -i -a ".\NvVAD\nvvad.inf"

echo. echo NVIDIA driver installation complete.