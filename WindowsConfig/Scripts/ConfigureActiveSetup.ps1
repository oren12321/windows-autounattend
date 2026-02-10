. "C:\MySetup\Scripts\Apply-Registry.ps1"

Write-Output "Starting Active Setup registration"

$entries = @(
    @{
        Path = "HKLM:\Software\Microsoft\Active Setup\Installed Components\UserSetup.PerUser"
        Name = "Version"
        Type = "String"
        Value = "1,0,0,0"
    },
    @{
        Path = "HKLM:\Software\Microsoft\Active Setup\Installed Components\UserSetup.PerUser"
        Name = "StubPath"
        Type = "String"
        Value = @"
cmd.exe /c start "Customizing User ... - Do Not Close The Window" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\MySetup\Scripts\RunActiveSetup.ps1"
"@
    },
    @{
        Path = "HKLM:\Software\Microsoft\Active Setup\Installed Components\UserSetup.PerUser"
        Name = "Locale"
        Type = "String"
        Value = "*"
    },
    @{
        Path = "HKLM:\Software\Microsoft\Active Setup\Installed Components\UserSetup.PerUser"
        Name = "IsInstalled"
        Type = "DWord"
        Value = 1
    }
)
Apply-RegistryBatch $entries

Write-Output "Active Setup registration done"