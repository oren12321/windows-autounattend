. "C:\MySetup\Scripts\Apply-Registry.ps1"

$entries = @(
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable control animations"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\AnimateMinMax"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable window minimize/maximize animation"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMAeroPeekEnabled"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable Aero Peek"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\MenuAnimation"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable menu animations"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TooltipAnimation"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable tooltip animations"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\SelectionFade"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable selection fade effect"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMSaveThumbnailEnabled"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable saving DWM thumbnails"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\CursorShadow"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable cursor shadow"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewShadow"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable listview shadows"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ThumbnailsOrIcon"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 1
        Description = "Enable thumbnails instead of icons"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListviewAlphaSelect"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable alpha selection"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DragFullWindows"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 1
        Description = "Enable dragging full windows"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ComboBoxAnimation"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable combo box animation"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\FontSmoothing"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 1
        Description = "Enable font smoothing"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ListBoxSmoothScrolling"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable smooth scrolling in list boxes"
    },
    @{
        Path        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DropShadow"
        Name        = "DefaultValue"
        Type        = "DWord"
        Value       = 0
        Description = "Disable window drop shadows"
    },
    @{
        Operation   = "Delete"
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
        Description = "Display the Home folder in the navigation pane as a shortcut to your user profile folder"
    },
    @{
        Operation   = "Delete"
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
        Description = "Display the Gallery folder in the navigation pane for quick access to all your photos and videos"
    },
    @{
        Operation   = "Delete"
        Path        = "HKCR:\*\shell\TakeOwnership"
        Description = "Adds a right-click option to take ownership of files, folders, and drives with automatic permission elevation"
    },
    @{
        Operation   = "Delete"
        Path        = "HKCR:\AllFilesystemObjects\shell\Windows.ShowFileExtensions"
        Description = "Adds a right-click menu option to quickly toggle file extension visibility in File Explorer (only visible on the Classic Context Menu or Show More Options Menu in Windows 11)"
    }
)
Apply-RegistryBatch $entries

# ============================================================================
# Take ownership option
# ============================================================================

try {
    $regContent_explorer_take_ownership = @'
Windows Registry Editor Version 5.00

; Created by: Shawn Brink
; Created on: January 28, 2015
; Updated on: February 25, 2024
; Tutorial: https://www.tenforums.com/tutorials/3841-add-take-ownership-context-menu-windows-10-a.html

[-HKEY_CLASSES_ROOT\*\shell\TakeOwnership]
[-HKEY_CLASSES_ROOT\*\shell\runas]

[HKEY_CLASSES_ROOT\*\shell\TakeOwnership]
@="Take Ownership"
"Extended"=-
"HasLUAShield"=""
"NoWorkingDirectory"=""
"NeverDefault"=""

[HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command]
@="powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/c takeown /f \\\"%1\\\" && icacls \\\"%1\\\" /grant *S-1-3-4:F /t /c /l & pause' -Verb runAs\""
"IsolatedCommand"="powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/c takeown /f \\\"%1\\\" && icacls \\\"%1\\\" /grant *S-1-3-4:F /t /c /l & pause' -Verb runAs\""

[HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership]
@="Take Ownership"
"AppliesTo"="NOT (System.ItemPathDisplay:=\"C:\\Users\" OR System.ItemPathDisplay:=\"C:\\ProgramData\" OR System.ItemPathDisplay:=\"C:\\Windows\" OR System.ItemPathDisplay:=\"C:\\Windows\\System32\" OR System.ItemPathDisplay:=\"C:\\Program Files\" OR System.ItemPathDisplay:=\"C:\\Program Files (x86)\")"
"Extended"=-
"HasLUAShield"=""
"NoWorkingDirectory"=""
"Position"="middle"

[HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command]
@="powershell -windowstyle hidden -command \"$Y = ($null | choice).Substring(1,1); Start-Process cmd -ArgumentList ('/c takeown /f \\\"%1\\\" /r /d ' + $Y + ' && icacls \\\"%1\\\" /grant *S-1-3-4:F /t /c /l /q & pause') -Verb runAs\""
"IsolatedCommand"="powershell -windowstyle hidden -command \"$Y = ($null | choice).Substring(1,1); Start-Process cmd -ArgumentList ('/c takeown /f \\\"%1\\\" /r /d ' + $Y + ' && icacls \\\"%1\\\" /grant *S-1-3-4:F /t /c /l /q & pause') -Verb runAs\""

[HKEY_CLASSES_ROOT\Drive\shell\runas]
@="Take Ownership"
"Extended"=-
"HasLUAShield"=""
"NoWorkingDirectory"=""
"Position"="middle"
"AppliesTo"="NOT (System.ItemPathDisplay:=\"C:\\\")"

[HKEY_CLASSES_ROOT\Drive\shell\runas\command]
@="cmd.exe /c takeown /f \"%1\\\" /r /d y && icacls \"%1\\\" /grant *S-1-3-4:F /t /c & Pause"
"IsolatedCommand"="cmd.exe /c takeown /f \"%1\\\" /r /d y && icacls \"%1\\\" /grant *S-1-3-4:F /t /c & Pause"

'@
    $tempRegFile = Join-Path $env:TEMP "temp_explorer-take-ownership_$((Get-Date).Ticks).reg"
    $regContent_explorer_take_ownership | Out-File -FilePath $tempRegFile -Encoding Unicode -Force
    reg import "$tempRegFile" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Adds a right-click option to take ownership of files, folders, and drives with automatic permission elevation"
    } else {
        Write-Output "Failed to import registry content for Adds a right-click option to take ownership of files, folders, and drives with automatic permission elevation"
    }
    Remove-Item $tempRegFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Output "Error processing registry content for Adds a right-click option to take ownership of files, folders, and drives with automatic permission elevation: $($_.Exception.Message)"
}

# ============================================================================
# Toggle file extension option
# ============================================================================

try {
    $regContent_explorer_context_menu_toggle_extensions = @'
Windows Registry Editor Version 5.00

[-HKEY_CLASSES_ROOT\AllFilesystemObjects\shell\Windows.ShowFileExtensions]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\Windows.ShowFileExtensions]

'@
    $tempRegFile = Join-Path $env:TEMP "temp_explorer-context-menu-toggle-extensions_$((Get-Date).Ticks).reg"
    $regContent_explorer_context_menu_toggle_extensions | Out-File -FilePath $tempRegFile -Encoding Unicode -Force
    reg import "$tempRegFile" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Adds a right-click menu option to quickly toggle file extension visibility in File Explorer (only visible on the Classic Context Menu or Show More Options Menu in Windows 11)"
    } else {
        Write-Output "Failed to import registry content for Adds a right-click menu option to quickly toggle file extension visibility in File Explorer (only visible on the Classic Context Menu or Show More Options Menu in Windows 11)"
    }
    Remove-Item $tempRegFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Output "Error processing registry content for Adds a right-click menu option to quickly toggle file extension visibility in File Explorer (only visible on the Classic Context Menu or Show More Options Menu in Windows 11): $($_.Exception.Message)"
}