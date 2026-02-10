function Get-AppEventsClearCurrentEntries {
    param()

    $eventLabelsPath = "HKCU:\AppEvents\EventLabels"
    $schemesRoot     = "HKCU:\AppEvents\Schemes\Apps"

    # Determine excluded event labels
    $excludes = Get-ChildItem -LiteralPath $eventLabelsPath |
        Where-Object { ($_ | Get-ItemProperty).ExcludeFromCPL -eq 1 } |
        Select-Object -ExpandProperty PSChildName

    $entries = @()

    Get-ChildItem -Path "$schemesRoot\*\*" |
        Where-Object { $_.PSChildName -notin $excludes } |
        Get-ChildItem -Include ".Current" |
        ForEach-Object {
            # .Name is like: HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\ChangeTheme\.Current
            $name = $_.Name
            $rel  = $name -replace '^HKEY_CURRENT_USER\\', '' -replace '^HKEY_LOCAL_MACHINE\\', ''
            $path = "HKCU:\$rel"

            $entries += @{
                Operation   = "Set"
                Path        = $path
                Name        = "(Default)"
                Type        = "String"
                Value       = ""
                Description = "Clear the current sound assigned to an application event"
            }
        }

    return $entries
}

$SoundAndNotificationsEntries = @(
    Get-AppEventsClearCurrentEntries
    @{
        Path        = "HKCU:\AppEvents\Schemes"
        Name        = "(Default)"
        Type        = "String"
        Value       = ".None"
        Description = "Disable all Windows sound schemes"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Multimedia\Audio"
        Name        = "UserDuckingPreference"
        Type        = "DWord"
        Value       = 3
        Description = "Automatically lower volume of media and apps when Windows detects communication activity"
    }
    @{
        Path        = "HKCU:\Software\Microsoft\Narrator\NoRoam"
        Name        = "DuckAudio"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Narrator to automatically lower the volume of other applications when it speaks"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility"
        Name        = "Sound on Activation"
        Type        = "DWord"
        Value       = 0
        Description = "Play sounds when accessibility features like StickyKeys or FilterKeys are activated"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility"
        Name        = "Warning Sounds"
        Type        = "DWord"
        Value       = 0
        Description = "Play warning sounds when attempting to activate accessibility features or when accessibility-related events occur"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
        Name        = "ToastEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Get notifications from apps and other senders in Windows"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        Name        = "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND"
        Type        = "DWord"
        Value       = 0
        Description = "Play audio alerts when notifications arrive from apps and system senders"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        Name        = "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK"
        Type        = "DWord"
        Value       = 0
        Description = "Display toast notifications on the lock screen when your device is locked"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
        Name        = "LockScreenToastEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Display toast notifications on the lock screen when your device is locked"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        Name        = "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK"
        Type        = "DWord"
        Value       = 0
        Description = "Display critical notifications like reminders and VoIP calls when your device is locked"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.CapabilityAccess"
        Name        = "Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Show notifications when apps request access to system capabilities and permissions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.StartupApp"
        Name        = "Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Show notifications when apps are added to your Windows startup list"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "DstNotification"
        Type        = "DWord"
        Value       = 0
        Description = "Show notifications when daylight saving time changes occur"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Narrator\NoRoam"
        Name        = "WinEnterLaunchEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Enable the Win+Ctrl+Enter keyboard shortcut to quickly launch Windows Narrator"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Name        = "Flags"
        Type        = "String"
        Value       = "2"
        Description = "Enable the keyboard shortcut to activate StickyKeys"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility\Keyboard Response"
        Name        = "Flags"
        Type        = "String"
        Value       = "2"
        Description = "Enable the keyboard shortcut to activate FilterKeys"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility\ToggleKeys"
        Name        = "Flags"
        Type        = "String"
        Value       = "34"
        Description = "Enable the keyboard shortcut to activate ToggleKeys"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility\MouseKeys"
        Name        = "Flags"
        Type        = "String"
        Value       = "130"
        Description = "Enable the keyboard shortcut to activate MouseKeys"
    },
    @{
        Path        = "HKCU:\Control Panel\Accessibility\HighContrast"
        Name        = "Flags"
        Type        = "String"
        Value       = "4194"
        Description = "Enable the keyboard shortcut to activate High Contrast mode"
    }
)