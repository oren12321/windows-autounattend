. "C:\MySetup\Scripts\Apply-Registry.ps1"

$entries = @(
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Name = "AUOptions"
        Type = "DWord"
        Value = 4
        Description="Control how automatic updates behave"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        Name = "DODownloadMode"
        Type = "DWord"
        Value = 99
        Description="Share downloaded updates with other PCs on your network or the internet to reduce bandwidth usage"
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        Name = "IsContinuousInnovationOptedIn"
        Type = "DWord"
        Value = 0
        Description="Be among the first to get the latest non-security updates, fixes, and improvements as they roll out"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "AllowMUUpdateService"
        Type = "DWord"
        Value = 0
        Description="Get Microsoft Office and other updates together with Windows updates"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "IsExpedited"
        Type = "DWord"
        Value = 0
        Description="Restart as soon as possible (even during active hours) to finish updating"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Name = "NoAutoRebootWithLoggedOnUsers"
        Type = "DWord"
        Value = 1
        Description="Prevents automatic restarts after installing updates when users are logged on"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name = "SetUpdateNotificationLevel"
        Type = "DWord"
        Value = 1
        Description="Show or hide notifications about available updates and update progress"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "RestartNotificationsAllowed2"
        Type = "DWord"
        Value = 0
        Description="Show notification when your device requires a restart to finish updating"
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        Name = "AllowAutoWindowsUpdateDownloadOverMeteredNetwork"
        Type = "DWord"
        Value = 0
        Description="Allow Windows to download updates when using mobile hotspots or data-limited connections"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name = "ExcludeWUDriversInQualityUpdate"
        Type = "DWord"
        Value = 1
        Description="Prevent Windows from automatically downloading and installing hardware driver updates"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        Name = "AutoDownload"
        Type = "DWord"
        Value = 2
        Description="Automatically download and install updates for apps from the Microsoft Store"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        Name        = "DisableAutomaticRestartSignOn"
        Type        = "DWord"
        Value       = 1
        Description = "Disable automatic restart sign-on after updates"
    }
)
Apply-RegistryBatch $entries

Register-ScheduledTask -TaskName 'PauseWindowsUpdate' -Xml $( Get-Content -LiteralPath 'C:\MySetup\Scripts\PauseWindowsUpdate.xml' -Raw );

Register-ScheduledTask -TaskName 'MoveActiveHoursPrimary' -Xml $( Get-Content -LiteralPath 'C:\MySetup\Scripts\MoveActiveHoursPrimary.xml' -Raw );
Register-ScheduledTask -TaskName 'MoveActiveHoursBackup' -Xml $( Get-Content -LiteralPath 'C:\MySetup\Scripts\MoveActiveHoursBackup.xml' -Raw );