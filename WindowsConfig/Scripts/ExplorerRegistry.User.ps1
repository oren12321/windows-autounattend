function Get-WallpaperConfigurationEntries {

    $entries = @()

    # Detect OS build
    $buildNumber = [System.Environment]::OSVersion.Version.Build
    $wallpaperPath = $null

    # Determine wallpaper based on OS version and theme
    if ($buildNumber -ge 22000) {
        $themeKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $lightTheme = $false

        if (Test-Path $themeKey) {
            $value = Get-ItemProperty -Path $themeKey -Name 'SystemUsesLightTheme' -ErrorAction SilentlyContinue
            if ($value.SystemUsesLightTheme -eq 1) {
                $lightTheme = $true
            }
        }

        if ($lightTheme) {
            $wallpaperPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
        } else {
            $wallpaperPath = 'C:\Windows\Web\Wallpaper\Windows\img19.jpg'
        }
    }
    else {
        $wallpaperPath = 'C:\Windows\Web\4K\Wallpaper\Windows\img0_3840x2160.jpg'
    }

    # If wallpaper file does not exist, return no entries
    if (-not (Test-Path $wallpaperPath)) {
        return @()   # No entries produced
    }

    # Wallpaper registry entries
    $entries += @(
        @{
            Operation   = "Set"
            Path        = "HKCU:\Control Panel\Desktop"
            Name        = "Wallpaper"
            Type        = "String"
            Value       = $wallpaperPath
            Description = "Set desktop wallpaper"
        },
        @{
            Operation   = "Set"
            Path        = "HKCU:\Control Panel\Desktop"
            Name        = "WallpaperStyle"
            Type        = "String"
            Value       = "10"
            Description = "Set wallpaper style (fill)"
        },
        @{
            Operation   = "Set"
            Path        = "HKCU:\Control Panel\Desktop"
            Name        = "TileWallpaper"
            Type        = "String"
            Value       = "0"
            Description = "Disable wallpaper tiling"
        },
        @{
            Operation   = "Delete"
            Path        = "HKCU:\Control Panel\Desktop"
            Name        = "TranscodedImageCache"
            Description = "Remove cached wallpaper image"
        },
        @{
            Operation   = "Delete"
            Path        = "HKCU:\Control Panel\Desktop"
            Name        = "TranscodedImageCache_000"
            Description = "Remove cached wallpaper image (secondary)"
        }
    )

    return $entries
}

$ExplorerEntries = @(
    @{
        Path        = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        Name        = "DisableSearchBoxSuggestions"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Bing search"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        Name        = "VisualFXSetting"
        Type        = "DWord"
        Value       = 3
        Description = "Choose the Windows visual effects performance mode"
    },
    @{
        Operation   = "Delete"
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Name        = "OneDriveSetup"
        Description = "Removes OneDriveSetup autorun entry for new users"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "HideFileExt"
        Type        = "DWord"
        Value       = 0
        Description = "Show file extensions for known file types"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Hidden"
        Type        = "DWord"
        Value       = 1
        Description = "Show hidden files and folders"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowSuperHidden"
        Type        = "DWord"
        Value       = 1
        Description = "Show protected operating system files"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "MenuShowDelay"
        Type        = "String"
        Value       = "0"
        Description = "Add a brief delay before displaying menus, or show them instantly for faster navigation"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\DWM"
        Name        = "CompositionPolicy"
        Type        = "DWord"
        Value       = 1
        Description = "Enable visual effects managed by the Desktop Window Manager"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 4
        BitIndex    = 1
        BitValue    = 0
        Description = "Enables animation effects for controls and UI elements"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop\WindowMetrics"
        Name        = "MinAnimate"
        Type        = "String"
        Value       = "0"
        Description = "Shows smooth animation when windows are minimized or maximized"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\DWM"
        Name        = "EnableAeroPeek"
        Type        = "DWord"
        Value       = 1
        Description = "Allows peeking at desktop when hovering over Show Desktop"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 0
        BitIndex    = 1
        BitValue    = 0
        Description = "Animates menus when they appear using fade or slide effects"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 1
        BitIndex    = 3
        BitValue    = 0
        Description = "Animates tooltips when they appear using fade or slide effects"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 1
        BitIndex    = 2
        BitValue    = 0
        Description = "Fades menu items after selection before closing the menu"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\DWM"
        Name        = "AlwaysHibernateThumbnails"
        Type        = "DWord"
        Value       = 0
        Description = "Saves thumbnail previews of taskbar windows for faster display"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 1
        BitIndex    = 5
        BitValue    = 0
        Description = "Displays shadow effect underneath the mouse cursor"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 2
        BitIndex    = 2
        BitValue    = 0
        Description = "Displays shadow effects underneath windows"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "IconsOnly"
        Type        = "DWord"
        Value       = 0
        Description = "Displays image and document previews instead of generic file icons"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ListviewAlphaSelect"
        Type        = "DWord"
        Value       = 1
        Description = "Display a semi-transparent selection box when dragging"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "DragFullWindows"
        Type        = "String"
        Value       = "1"
        Description = "Displays window contents when dragging instead of just an outline"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 0
        BitIndex    = 2
        BitValue    = 0
        Description = "Animates combo boxes when they open with a sliding effect"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "FontSmoothing"
        Type        = "String"
        Value       = "2"
        Description = "Apply anti-aliasing to text for smoother, more readable fonts"
    },
    @{
        Operation   = "SetBit"
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "UserPreferencesMask"
        Offset      = 0
        BitIndex    = 3
        BitValue    = 0
        Description = "Enables smooth scrolling in list boxes instead of jumping"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ListviewShadow"
        Type        = "DWord"
        Value       = 0
        Description = "Add shadow effects behind desktop icon text"
    },
    @{
        Operation   = "EnsureKey"
        Path        = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        Description = "Use the Windows 10-style right-click menu with all options visible instead of the simplified Windows 11 menu"
    },
    @{
        Path        = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        Name        = "(Default)"
        Type        = "String"
        Value       = ""
        Description = "Use the Windows 10-style right-click menu with all options visible instead of the simplified Windows 11 menu"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Lighting"
        Name        = "AmbientLightingEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Windows Dynamic Lighting to control ambient RGB effects on compatible devices"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Lighting"
        Name        = "ControlledByForegroundApp"
        Type        = "DWord"
        Value       = 0
        Description = "Allow compatible apps to control device lighting effects"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
        Name        = "LegacyDefaultPrinterMode"
        Type        = "DWord"
        Value       = 1
        Description = "Prevents Windows from automatically changing your default printer based on location or last used printer"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "LaunchTo"
        Type        = "DWord"
        Value       = 1
        Description = "Choose what happens when File Explorer is opened"
    },
    @{
        Operation   = "SetByte"
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"
        Name        = "Settings"
        Offset      = 4
        ByteValue   = 0x0A
        Description = "Choose whether each folder opens in the same window or in its own window"
    },
    @{
        Operation   = "SetByte"
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "ShellState"
        Offset      = 4
        ByteValue   = 0x3E
        Description = "Choose whether to open files and folders with a single click or double-click"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "IconUnderline"
        Type        = "DWord"
        Value       = 3
        Description = "Choose whether to open files and folders with a single click or double-click"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "ShowRecent"
        Type        = "DWord"
        Value       = 0
        Description = "Displays recently accessed files and recommendations in Quick Access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "ShowRecommendations"
        Type        = "DWord"
        Value       = 0
        Description = "Displays recently accessed files and recommendations in Quick Access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "ShowFrequent"
        Type        = "DWord"
        Value       = 0
        Description = "Displays your most accessed folders in Quick Access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
        Name        = "ShowCloudFilesInQuickAccess"
        Type        = "DWord"
        Value       = 0
        Description = "Displays cloud files from your Office.com account in Quick Access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "IconsOnly"
        Type        = "DWord"
        Value       = 0
        Description = "Displays generic file icons instead of image/document previews"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "UseCompactMode"
        Type        = "DWord"
        Value       = 0
        Description = "Reduces vertical spacing between files and folders for denser view"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowTypeOverlay"
        Type        = "DWord"
        Value       = 1
        Description = "Shows file type icon overlay on thumbnail previews"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "FolderContentsInfoTip"
        Type        = "DWord"
        Value       = 1
        Description = "Shows total size and file count when hovering over folders"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"
        Name        = "FullPath"
        Type        = "DWord"
        Value       = 1
        Description = "Shows complete directory path in window title"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Hidden"
        Type        = "DWord"
        Value       = 1
        Description = "Displays items with the hidden attribute set"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "HideDrivesWithNoMedia"
        Type        = "DWord"
        Value       = 1
        Description = "Hides drives with no media inserted"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "HideFileExt"
        Type        = "DWord"
        Value       = 0
        Description = "Displays file type extensions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "HideMergeConflicts"
        Type        = "DWord"
        Value       = 0
        Description = "Automatically merges folders with same name without confirmation"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowSuperHidden"
        Type        = "DWord"
        Value       = 1
        Description = "Displays system files marked with the SuperHidden attribute"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "SeparateProcess"
        Type        = "DWord"
        Value       = 0
        Description = "Runs each Explorer window in its own process"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "PersistBrowsers"
        Type        = "DWord"
        Value       = 0
        Description = "Reopens Explorer windows from last session"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowDriveLettersFirst"
        Type        = "DWord"
        Value       = 4
        Description = "Displays drive letters before drive names"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowEncryptCompressedColor"
        Type        = "DWord"
        Value       = 1
        Description = "Displays encrypted files in green and compressed files in blue"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowInfoTip"
        Type        = "DWord"
        Value       = 1
        Description = "Displays tooltip with item details when hovering"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowPreviewHandlers"
        Type        = "DWord"
        Value       = 0
        Description = "Enables file content preview when selecting files"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowStatusBar"
        Type        = "DWord"
        Value       = 1
        Description = "Displays bar at bottom showing item count and file sizes"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowSyncProviderNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Displays cloud sync status notifications"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "AutoCheckSelect"
        Type        = "DWord"
        Value       = 0
        Description = "Adds checkboxes next to items for easier multi-selection"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "SharingWizardOn"
        Type        = "DWord"
        Value       = 0
        Description = "Shows simplified sharing dialog instead of advanced permissions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "TypeAhead"
        Type        = "DWord"
        Value       = 0
        Description = "Chooses whether typing selects matching items or searches automatically"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "NavPaneShowAllCloudStates"
        Type        = "DWord"
        Value       = 0
        Description = "Shows cloud sync status icons in navigation pane"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "NavPaneExpandToCurrentFolder"
        Type        = "DWord"
        Value       = 0
        Description = "Automatically expands navigation tree to current folder"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "NavPaneShowAllFolders"
        Type        = "DWord"
        Value       = 0
        Description = "Shows all folders in the navigation pane"
    },
    @{
        Path        = "HKCU:\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}"
        Name        = "System.IsPinnedToNameSpaceTree"
        Type        = "DWord"
        Value       = 0
        Description = "Displays Libraries container grouping Documents, Music, Pictures, and Videos"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Name        = "AppsUseLightTheme"
        Type        = "DWord"
        Value       = 0
        Description = "Choose between Light and Dark mode for Windows and apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Name        = "SystemUsesLightTheme"
        Type        = "DWord"
        Value       = 0
        Description = "Choose between Light and Dark mode for Windows and apps"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Name        = "EnableTransparency"
        Type        = "DWord"
        Value       = 0
        Description = "Enable translucent effects for the Start Menu, taskbar, and other Windows interface elements"
    }
)
