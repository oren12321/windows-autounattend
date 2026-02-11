. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path        = "HKLM:\SYSTEM\Setup\MoSetup"
        Name        = "AllowUpgradesWithUnsupportedTPMOrCPU"
        Type        = "DWord"
        Value       = 1
        Description = "Allow in-place upgrades on unsupported TPM or CPU hardware"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
        Name        = "BypassNRO"
        Type        = "DWord"
        Value       = 1
        Description = "Bypass network requirement during Windows out-of-box experience"
    },
    @{
        Operation   = "Delete"
        Path        = "HKLM:\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate"
        Description = "Remove Dev Home update scheduled during OOBE"
    },
    @{
        Operation   = "Delete"
        Path        = "HKLM:\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"
        Description = "Remove Outlook update scheduled during OOBE"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education"
        Name        = "IsEducationEnvironment"
        Type        = "DWord"
        Value       = 1
        Description = "Enable education environment mode"
    }
)
Apply-RegistryBatch $entries