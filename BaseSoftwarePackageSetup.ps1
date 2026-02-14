<#
===========================================================================================
    Windows Workstation Automated Software Installation Script
===========================================================================================

    This script automates the setup of a complete Windows workstation by installing
    a curated collection of applications using both **winget** and **Chocolatey**.
    It is designed to streamline fresh installations, provisioning, or system rebuilds.

    -----------------------------------------
    WHAT THE SCRIPT DOES
    -----------------------------------------
    • Enables required execution policies and installs Chocolatey.
    • Installs software in organized categories using winget and choco.
    • Performs silent unattended installations where possible.
    • Downloads and installs Micro‑Cap 12 using a generated InstallShield response file.
    • Cleans up temporary files created during installation.

    -----------------------------------------
    SOFTWARE INSTALLED BY CATEGORY
    -----------------------------------------

    INTERNET
        - Mozilla Firefox
        - Brave Browser
        - qBittorrent

    FILE MANAGEMENT
        - OneCommander
        - Everything
        - 7‑Zip
        - LocalSend
        - WinMerge

    DOCUMENTS & TEXT
        - ONLYOFFICE Desktop Editors
        - PDFgear
        - Notepad++
        - MarkText

    MEDIA (PHOTO, VIDEO, AUDIO)
        - GIMP 3
        - VLC Media Player
        - LosslessCut
        - Shotcut
        - Audacity
        - OBS Studio
        - HandBrake (choco)
        - Equalizer APO (choco)

    PEN & DRAWING
        - Krita
        - Microsoft Journal (Microsoft Store)
        - Concepts (Microsoft Store)

    TWEAKS
        - Microsoft PowerToys

    MONITORING & TESTING
        - HWiNFO
        - OCCT
        - CrystalDiskInfo
        - WizTree
        - MSI Afterburner
        - Wireshark
        - Sysinternals Process Monitor
        - Sysinternals Process Explorer

    CLEANUP & MAINTENANCE
        - Bulk Crap Uninstaller (BCUninstaller)
        - BleachBit

    DISK & RECOVERY
        - Ventoy
        - Rufus
        - Hasleo Backup Suite Free
        - AnyBurn
        - TestDisk & PhotoRec (choco)

    SOFTWARE DEVELOPMENT
        - VSCodium
        - Git
        - Fork
        - DBeaver Community
        - Insomnia
        - DevToys
        - VirtualBox + Extension Pack (choco)
        - Micro‑Cap 12 (silent InstallShield setup)

    COMMUNICATION
        - Signal
        - Zoom
        - Microsoft Teams
        - Discord
        - Slack
        - WhatsApp

===========================================================================================
#>

Write-Host "Installing Chocolatey" -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

##########################################################################################################################

Write-Host "Installing INTERNET Software..." -ForegroundColor Cyan
$wingetApps = @(
    "Mozilla.Firefox", "Brave.Brave", "qBittorrent.qBittorrent"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing FILE MANAGEMENT Software..." -ForegroundColor Cyan
$wingetApps = @(
    "MilosParipovic.OneCommander", "voidtools.Everything", "7zip.7zip", "LocalSend.LocalSend", "WinMerge.WinMerge"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing DOCUMENTS & TEXT Software..." -ForegroundColor Cyan
$wingetApps = @(
    "ONLYOFFICE.DesktopEditors", "PDFgear.PDFgear", "Notepad++.Notepad++", "MarkText.MarkText"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing MEDIA (PHOTO, VIDEO, AUDIO) Software..." -ForegroundColor Cyan
$wingetApps = @(
    "GIMP.GIMP.3", "VideoLAN.VLC", "ch.LosslessCut", "Meltytech.Shotcut", "Audacity.Audacity", "OBSProject.OBSStudio"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}

$chocoApps = @(
    "handbrake", "equalizerapo"
)
foreach ($app in $chocoApps) {
    choco install $app -y --no-progress
}
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing PEN & DRAWING Software..." -ForegroundColor Cyan
winget install -e --id KDE.Krita --source winget --scope machine --accept-package-agreements --accept-source-agreements
winget install "Microsoft Journal" --source msstore --silent --accept-package-agreements --accept-source-agreements
winget install "Concepts" --source msstore --silent --accept-package-agreements --accept-source-agreements
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing TWEAKS Software..." -ForegroundColor Cyan
winget install -e --id Microsoft.PowerToys --source winget --scope machine --accept-package-agreements --accept-source-agreements
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing MONITORING & TESTING Software..." -ForegroundColor Cyan
$wingetApps = @(
    "REALiX.HWiNFO", "CrystalDewWorld.CrystalDiskInfo", "AntibodySoftware.WizTree",
    "Guru3D.Afterburner", "WiresharkFoundation.Wireshark", "Microsoft.Sysinternals.ProcessMonitor", "Microsoft.Sysinternals.ProcessExplorer"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}

choco install occt -y --no-progress
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing CLEANUP & MAINTENANCE Software..." -ForegroundColor Cyan
$wingetApps = @(
    "Klocman.BulkCrapUninstaller", "BleachBit.BleachBit"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing DISK & RECOVERY Software..." -ForegroundColor Cyan
$wingetApps = @(
    "Ventoy.Ventoy", "Rufus.Rufus", "PowerSoftware.AnyBurn"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}

choco install testdisk-photorec -y --no-progress
choco install hasleobackupsuite -y --no-progress --ignore-checksum
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing SOFTWARE DEVELOPMENT Software..." -ForegroundColor Cyan
$wingetApps = @(
    "VSCodium.VSCodium", "Git.Git", "Fork.Fork", "DBeaver.DBeaver.Community", "Insomnia.Insomnia", "DevToys-app.DevToys"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}

choco install virtualbox -y --no-progress --params "/ExtensionPack"

Write-Host "Installing Micro-Cap 12..." -ForegroundColor Yellow
$iss = @'
[InstallShield Silent]
Version=v7.00
File=Response File
[File Transfer]
OverwrittenReadOnly=NoToAll
[Application]
Name=Micro-Cap 12
Version=12.2.0.3
Company=Spectrum Software
Lang=0409
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-DlgOrder]
Dlg0={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdWelcome-0
Count=9
Dlg1={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdAskDestPath-0
Dlg2={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdLicense-0
Dlg3={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdRegisterUser-0
Dlg4={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdComponentDialog2-0
Dlg5={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdSelectFolder-0
Dlg6={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-AskOptions-0
Dlg7={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdStartCopy-0
Dlg8={6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdFinish-0
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdWelcome-0]
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdAskDestPath-0]
szDir=C:\MC12
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdLicense-0]
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdRegisterUser-0]
szName=user
szCompany=company
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdComponentDialog2-0]
Component-type=string
Component-count=6
Component-0=PRO\Program Files
Component-1=PRO\Help Files
Component-2=PRO\Sample Circuits
Component-3=PRO\Shape And Component Libraries
Component-4=PRO\Model Libraries
Component-5=PRO\Manuals
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdSelectFolder-0]
szFolder=Micro-Cap 12
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-AskOptions-0]
Result=1
Sel-0=1
Sel-1=1
Sel-2=0
Sel-3=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdStartCopy-0]
Result=1
[{6DF8477A-6C32-407B-9EB4-25B1F0A1A350}-SdFinish-0]
Result=1
bOpt1=0
bOpt2=0
'@
$iss | Out-File -FilePath "C:\setup.iss"
Start-BitsTransfer -Source "https://gotroot.ca/spectrum/www.spectrum-soft.com/download/mc12cd.zip" -Destination "$env:TEMP\mc12cd.zip"
Expand-Archive -Path "$env:TEMP\mc12cd.zip" -DestinationPath "$env:TEMP\mc12"
Start-Process "$env:TEMP\mc12\setup.exe" -ArgumentList '/s /f1"C:\setup.iss"' -Wait
Remove-Item -Path "$env:TEMP\mc12" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\mc12cd.zip" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\setup.iss" -Force -ErrorAction SilentlyContinue

Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################

Write-Host "Installing COMMUNICATION Software..." -ForegroundColor Cyan
$wingetApps = @(
    "OpenWhisperSystems.Signal", "Zoom.Zoom",
    "Discord.Discord", "SlackTechnologies.Slack", "WhatsApp.WhatsApp"
)
foreach ($app in $wingetApps) {
    winget install -e --id $app --source winget --scope machine --accept-package-agreements --accept-source-agreements
}

choco install microsoft-teams-new-bootstrapper -y --no-progress
Write-Host "Done." -ForegroundColor Cyan

##########################################################################################################################
