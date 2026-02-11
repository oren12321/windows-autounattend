. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable taskbar animations"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"
        Name        = "HideRecommendedSection"
        Type        = "DWord"
        Value       = 1
        Description = "Show or hide the lower section that displays recently opened files and suggested apps"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        Name        = "HideSCAMeetNow"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Meet Now Icon"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Chat"
        Name        = "ChatIcon"
        Type        = "DWord"
        Value       = 3
        Description = "Disable Windows 11 Chat Icon"
    }
)
Apply-RegistryBatch $entries

function Invoke-ConfigureStartPins {
    $json = '{"pinnedList":[]}'
    if ([System.Environment]::OSVersion.Version.Build -lt 20000) {
        return
    }
    $key = 'Registry::HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
    New-Item -Path $key -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins' -Value $json -Type String
}
Invoke-ConfigureStartPins