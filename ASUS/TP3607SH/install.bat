@echo off
setlocal

set DRYRUN=1

set "orig=%cd%"

echo #########################################
echo CHIPSET
echo #########################################

call :runInstaller "Chipset\INFUpdate_DCH_Intel_D_V10.1.48.18_42321_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\SerialIO_Intel_D_V30.100.2416.40_42322_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\DPTF_DCH_Intel_D_V2.2.10003.3_42323_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\HIDEVENTFilter_DCH_Intel_D_V2.2.2.11_42325_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\SensorHub_DCH_Intel_D_V5.8.36.0_42326_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\ICSS_DCH_Intel_X_V2.1.10500.0007_41056_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\PMT_Intel_D_V5.2.3.4_42333_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\TXT_DCH_Intel_D_V1.20.16.0_42330_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\MEI_Consumer_DCH_Intel_D_V2452.7.1.0_43060_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Chipset\NPU_DCH_Intel_D_V32.0.100.4239_45000" "install.bat"
if errorlevel 1 goto :end

echo #########################################
echo AUDIO
echo #########################################

call :runInstaller "Audio\iSST_DCH_Intel_D_V20.42.12134.0_47594" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Audio\Audio_DriverOnly_Dolby_DCH_Realtek_D_V6.0.9818.1_43360_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Audio\SmartAMP_TI_DCH_TexasInstruments_D_V3.1.26.4_41982_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Audio" "DolbyAtmosdriverforConsumer_ASUS_Z_V10.1031.743.43_17160.exe"
if errorlevel 1 goto :end

echo #########################################
echo GRAPHICS
echo #########################################

call :runInstaller "Graphics\Graphic_IGCC_DCH_Intel_D_V32.0.101.6556_43364_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Graphics\591.74-notebook-win10-win11-64bit-international-nsd-dch-whql" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Graphics\591.74-notebook-win10-win11-64bit-international-nsd-dch-whql\Display.Driver\NVCPL" "powershell -Command Add-AppxPackage -Path '.\7e010d7e2de54a439dbd340dd1f61212.appx'"
if errorlevel 1 goto :end

echo #########################################
echo NETWORK
echo #########################################

call :runInstaller "Network\Bluetooth_DCH_Intel_Z_V23.160.0.9_44629" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Network\WirelessLan_PIE_DCH_Intel_Z_V23.160.0.4_44628" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Network\WirelessLan_ICPS_Intel_D_V4.1024.1009.5_42336_1" "install.bat"
if errorlevel 1 goto :end

call :runInstaller "Network\Wi-Fi_sensing_DCH_Intel_D_V23.130.1.1_43356_1" "install.bat"
if errorlevel 1 goto :end

echo #########################################
echo CARD READER
echo #########################################

call :runInstaller "Card Reader\CardReader_DCH_Genesys_D_V4.5.11.300_42328_1" "install.bat"
if errorlevel 1 goto :end

echo #########################################
echo POINTING DEVICE
echo #########################################

call :runInstaller "Pointing Device\PrecisionTouchPad_DCH_ASUS_X_V16.0.0.36_43216_1" "install.bat"
if errorlevel 1 goto :end

echo #########################################
echo ASUS SOFTWARE
echo #########################################

call :runInstaller "Software and Utility" "ASUSSystemControlInterfacev3_ASUS_Z_V3.1.59.0_17476.exe"
if errorlevel 1 goto :end

echo.
echo All installations completed successfully.
goto :end


:runInstaller
    REM %~1 = directory to cd into
    REM %*  = all arguments
    REM shift removes the first argument so %* becomes the command

    set "dir=%~1"
    set "cmd=%~2"

    echo -----------------------------------------
    echo Running %cmd% in %dir% ...
    echo -----------------------------------------

    REM DRY RUN MODE
    if "%DRYRUN%"=="1" (
        echo [DRY RUN] Would CD to: "%orig%\%dir%"
        echo [DRY RUN] Would run:   %cmd%
        echo.
        exit /b 0
    )

    REM REAL EXECUTION MODE
    cd /d "%orig%\%dir%"
    call %cmd%

    if errorlevel 1 (
        echo ERROR: Installation failed for %cmd%
        cd /d "%orig%"
        echo.
        exit /b 1
    )

    cd /d "%orig%"
    echo Completed %cmd% successfully.
    echo.
    exit /b 0
    

:end
echo.
echo Script finished.
rem no exit here, terminal stays open