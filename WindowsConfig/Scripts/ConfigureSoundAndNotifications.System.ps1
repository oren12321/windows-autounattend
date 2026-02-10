. "C:\MySetup\Scripts\Apply-Registry.ps1"

$entries = @(
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation"
        Name        = "DisableStartupSound"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Windows startup sound"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\EditionOverrides"
        Name        = "UserSetting_DisableStartupSound"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Windows startup sound"
    }
)
Apply-RegistryBatch $entries