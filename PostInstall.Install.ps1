# That script require admin user

param(
    [string]$InstallDirectory = "C:\Windows\Scripts",
    [switch]$Uninstall
)

function Undo-PostInstall {
    Write-Output "[INFO] Starting undo PostInstall installation"
    
    if (Test-Path "$InstallDirectory\PostInstall") {
        Write-Output "[INFO] Removing copied files"
        try {
            Remove-Item -Path "$InstallDirectory\PostInstall" -Recurse -Force | Out-Null
        }
        catch {
            Write-Output "[WARNING] Failed to remove copied files: $_"
        }
    }
    
    $exists = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "PostInstallDirectory" -ErrorAction SilentlyContinue)
    if ($exists) {
        try {
            Write-Output "[INFO] Removing environment variable PostInstallDirectory"
            [Environment]::SetEnvironmentVariable("PostInstallDirectory", $null, "Machine")
        }
        catch {
            Write-Output "[WARNING] Failed to remove environment vaariable PostInstallDirectory: $_"
        }
    }
    
    if (Get-ScheduledTask -TaskName "PostInstall" -ErrorAction SilentlyContinue) {
        Write-Output "[INFO] Removing scheduled task"
        try {
            Unregister-ScheduledTask -TaskName "PostInstall" -Confirm:$false | Out-Null
        }
        catch {
            Write-Output "[WARNING] Failed to remove scheduled task"
        }
    }
    
    Write-Output "[INFO] Undo PostInstall installation finished"
}

if ($Uninstall) {
    Undo-PostInstall
    return
}

Write-Output "Starting PostInstall installation"

if (-not (Test-Path $InstallDirectory)) {
    Write-Output "[ERROR] Install directory $InstallDirectory does not exist"
    Write-Output "[INFO] Installation stopped"
    return
}

try {
    Write-Output "[INFO] Copying files to $InstallDirectory"
    Copy-Item -Path ".\PostInstall" -Destination $InstallDirectory -Recurse -Force | Out-Null
}
catch {
    Write-Output "[ERROR] Failed Copying files to ${InstallDirectory}: $_"
    Undo-PostInstall
    return
}

try {
    Write-Output "[INFO] Creating environment variable PostInstallDirectory=$InstallDirectory\PostInstall for all users"
    [Environment]::SetEnvironmentVariable("PostInstallDirectory", "$InstallDirectory\PostInstall", "Machine")
}
catch {
    Write-Output "[ERROR] Failed to create environment variable PostInstallDirectory=$InstallDirectory\PostInstall: $_"
    Undo-PostInstall
    return
}

try {
    Write-Output "[INFO] Configuring scheduled task runner - components directory: %LOCALAPPDATA%\Components"
    $ps1 = (Get-Content -LiteralPath ".\PostInstall\PostInstall.Run.ps1" -Raw)
    $ps1 = $ps1.Replace("{InstallDirectory}", $InstallDirectory)
    $ps1 = $ps1.Replace("{ComponentsDirectory}", "%LOCALAPPDATA%\Components")
    $ps1 | Set-Content "$InstallDirectory\PostInstall\PostInstall.Run.ps1"
}
catch {
    Write-Output "[ERROR] Failed to configure scheduled task runner: $_"
    Undo-PostInstall
    return
}

try {
    Write-Output "[INFO] Configuring scheduled task XML"
    $xml = (Get-Content -LiteralPath ".\PostInstall.Task.xml" -Raw)
    $xml = $xml.Replace("{InstallDirectory}", $InstallDirectory)
}
catch {
    Write-Output "[ERROR] Failed to configure scheduled task XML: $_"
    Undo-PostInstall
    return
}

try {
    Write-Output "[INFO] Registering scheduled task"
    Register-ScheduledTask -TaskName "PostInstall" -Xml $xml | Out-Null
}
catch {
    Write-Output "[ERROR] Failed to register scheduled task: $_"
    Undo-PostInstall
}

Write-Output "PostInstall installation finished"