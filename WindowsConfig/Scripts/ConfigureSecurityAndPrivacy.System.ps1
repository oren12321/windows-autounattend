. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name = "ConsentPromptBehaviorAdmin"
        Type = "DWord"
        Value = 0
        Description = "Defines how Windows prompts administrators for approval when elevated permissions are required."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name = "PromptOnSecureDesktop"
        Type = "DWord"
        Value = 0
        Description = "Determines whether UAC prompts appear on the secure desktop for added protection."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Name = "EnableLUA"
        Type = "DWord"
        Value = 0
        Description = "Disable UAC"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin"
        Name = "BlockAADWorkplaceJoin"
        Type = "DWord"
        Value = 1
        Description = "Prevents users from joining Azure AD or seeing prompts to let the organization manage the device."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
        Name = "PreventDeviceEncryption"
        Type = "DWord"
        Value = 1
        Description = "Stops Windows from automatically enabling BitLocker device encryption."
    },
    @{
        Path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        Name = "Value"
        Type = "DWord"
        Value = 0
        Description = "Disables Wi‑Fi Sense features that share Wi‑Fi credentials and connect to suggested hotspots."
    },
    @{
        Path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        Name = "Value"
        Type = "DWord"
        Value = 0
        Description = "Prevents automatic connection to open or suggested Wi‑Fi Sense hotspots."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"
        Name = "MaintenanceDisabled"
        Type = "DWord"
        Value = 1
        Description = "Disables automatic system maintenance tasks that normally run during idle time."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
        Name = "Disabled"
        Type = "DWord"
        Value = 1
        Description = "Turns off Windows Error Reporting so crash and diagnostic data is not sent to Microsoft."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
        Name = "fAllowToGetHelp"
        Type = "DWord"
        Value = 0
        Description = "Blocks Remote Assistance so others cannot connect to provide remote help."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Name = "DisableLockWorkstation"
        Type = "DWord"
        Value = 0
        Description = "Controls whether users are allowed to lock the workstation using Windows security shortcuts."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        Name = "DisabledByGroupPolicy"
        Type = "DWord"
        Value = 1
        Description = "Disables the advertising ID used by apps to deliver personalized ads."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Name = "AllowTelemetry"
        Type = "DWord"
        Value = 1
        Description = "Sets the level of diagnostic data Windows is allowed to send to Microsoft."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Name = "MaxTelemetryAllowed"
        Type = "DWord"
        Value = 1
        Description = "Defines the maximum diagnostic data level permitted on the device."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        Name = "AllowTelemetry"
        Type = "DWord"
        Value = 1
        Description = "Specifies whether diagnostic data collection is permitted by policy."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        Name = "DoNotShowFeedbackNotifications"
        Type = "DWord"
        Value = 1
        Description = "Suppresses Windows feedback notifications that request user input."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Name = "AllowCortana"
        Type = "DWord"
        Value = 0
        Description = "Enables or disables the Cortana assistant for search and voice interaction."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        Name = "Value"
        Type = "String"
        Value = "Deny"
        Description = "Controls whether Windows and apps are allowed to access the device’s location."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        Name = "DisableLocation"
        Type = "DWord"
        Value = 1
        Description = "Disables all location services and prevents apps from accessing location data."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
        Name = "Value"
        Type = "String"
        Value = "Allow"
        Description = "Specifies whether apps are permitted to access the device camera."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
        Name = "Value"
        Type = "String"
        Value = "Allow"
        Description = "Specifies whether apps are permitted to access the device microphone."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation"
        Name = "Value"
        Type = "String"
        Value = "Deny"
        Description = "Controls whether apps can access user account information."
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics"
        Name = "Value"
        Type = "String"
        Value = "Deny"
        Description = "Controls whether apps can access diagnostic information about other apps."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name = "KFMBlockOptIn"
        Type = "DWord"
        Value = 1
        Description = "Prevents OneDrive from offering or enabling automatic backup of user folders."
    },
    @{
        Path  = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
        Name  = "ExecutionPolicy"
        Type  = "String"
        Value = "RemoteSigned"
        Description = "Set PowerShell execution policy"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Microsoft\PowerShellCore\ShellIds\Microsoft.PowerShell"
        Name  = "ExecutionPolicy"
        Type  = "String"
        Value = "RemoteSigned"
        Description = "Set PowerShell Core execution policy"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"
        Name        = "AgentActivationEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable voice activation features"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\SpeechOneCore\Settings"
        Name        = "AgentActivationLastUsed"
        Type        = "DWord"
        Value       = 0
        Description = "Reset last used voice activation state"
    },
    @{
        Path        = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        Name        = "VerifiedAndReputablePolicyState"
        Type        = "DWord"
        Value       = 0
        Description = "Disable Smart App Control verified and reputable policy"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications"
        Name        = "ConfigureChatAutoInstall"
        Type        = "DWord"
        Value       = 0
        Description = "Disable automatic installation of Microsoft Chat"
    },
    @{
        Path        = "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"
        Name        = "DisableWindowsConsumerFeatures"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Windows consumer features and suggestions"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows Defender Security Center\Notifications"
        Name        = "DisableNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Show all Windows Security notifications"
    },
    @{
        Path        = "HKLM:\Software\Policies\Microsoft\Windows Defender Security Center\Notifications"
        Name        = "DisableNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Show all Windows Security notifications"
    },
    @{
        Path        = "HKLM:\Software\Policies\Microsoft\Windows Defender Security Center\Notifications"
        Name        = "DisableEnhancedNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Show enhanced Windows Security notifications"
    }
)
Apply-RegistryBatch $entries

net.exe accounts /maxpwage:UNLIMITED

Disable-ComputerRestore -Drive 'C:\'
