
<#
OLED Care Setup
---------------
This is a script that modify Windows settings and install some 3rd party
software in order to prevent OLED screen burn-in.
#>

###########################################################
#################### Desktop Slideshow --------------------
###########################################################

function Get-WindowsDefaultThemePath {
    # Known default theme file for both Windows 10 and 11
    $defaultTheme = "C:\Windows\Resources\Themes\aero.theme"

    if (Test-Path $defaultTheme) {
        return $defaultTheme
    }
    else {
        Write-Output "Default theme file not found at expected location."
        return $null
    }
}

function Create-SlideshowFolder {
    param(
        [string]$InputFolder
    )
    if (-not (Test-Path -LiteralPath $InputFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $InputFolder | Out-Null
    }
    
    if (-not (Get-ChildItem $InputFolder -File -ErrorAction SilentlyContinue)) {
        $possibleWallpapers = @(
            "C:\Windows\Web\Wallpaper\Windows\img0.jpg",
            "C:\Windows\Web\Wallpaper\Windows\img0.png",
            "C:\Windows\Web\Wallpaper\Theme1\img1.jpg",
            "C:\Windows\Web\Wallpaper\Theme1\img1.png"
        )
        $defaultWallpaper = $possibleWallpapers | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($defaultWallpaper) {
            Copy-Item $defaultWallpaper "$InputFolder\DefaultWallpaper.jpg" -Force
        }
    }
}

function New-SlideshowTheme {
    param(
        [string]$InputThemePath,
        [int]$IntervalMinutes,
        [string]$ImagesFolder,
        [string]$OutputThemePath
    )
    
    if (-not (Test-Path $InputThemePath)) {
        return [pscustomobject]@{
            Success = $false
            Value   = $null
            Error   = "Could not find input theme: $InputThemePath"
        }
    }
    
    if (($IntervalMinutes -lt 1) -or ($IntervalMinutes -gt (24 * 60))) {
        return [pscustomobject]@{
            Success = $false
            Value   = $null
            Error   = "Illegal interval $IntervalMinutes, must be between 1 minute to 1 day"
        }
    }
    
    if (-not (Test-Path -LiteralPath $ImagesFolder -PathType Container)) {
        return [pscustomobject]@{
            Success = $false
            Value   = $null
            Error   = "Could not find images folder: $ImagesFolder"
        }
    }
    
    $themeLines = Get-Content $InputThemePath
    
    $cleanedLines = New-Object System.Collections.Generic.List[string]
    
    $inSlideshowSection = $false
    foreach ($line in $themeLines) {
        if ($line -match "^\[Slideshow\]") {
            $inSlideshow = $true
            continue
        }
        if ($inSlideshow -and $line -match "^\[.+\]") {
            # End of slideshow block
            $inSlideshow = $false
        }
        if (-not $inSlideshow) {
            $cleanedLines.Add($line)
        }
    }
    
    $IntervalMs = $IntervalMinutes * 60 * 1000
    $cleanedLines.Add("[Slideshow]")
    $cleanedLines.Add("Interval=$IntervalMs")
    $cleanedLines.Add("Shuffle=1")
    $cleanedLines.Add("ImagesRootPath=$ImagesFolder")
    
    $dir = Split-Path -Path $OutputThemePath -Parent
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    New-Item -ItemType File -Path $OutputThemePath -Force
    $cleanedLines | Set-Content -Path $OutputThemePath -Encoding Unicode
    
    return [pscustomobject]@{
        Success = $true
        Value   = $OutputThemePath
        Error   = ""
    }
}

function Apply-Theme {
    param(
        [string]$ThemePath
    )
    
    if (-not (Test-Path $ThemePath)) {
        return [pscustomobject]@{
            Success = $false
            Error   = "Could not find theme file: $ThemePath"
        }
    }
    
    Start-Process $ThemePath
    Start-Sleep -Seconds 1  # give Explorer time to apply

    # Wait for SystemSettings.exe to appear (up to 3 seconds)
    $deadline = (Get-Date).AddSeconds(3)
    do {
        $settings = Get-Process -Name SystemSettings -ErrorAction SilentlyContinue
        if ($settings) { break }
        Start-Sleep -Milliseconds 150
    } while ((Get-Date) -lt $deadline)

    if ($settings) {
        # Try graceful close
        foreach ($proc in $settings) {
            $null = $proc.CloseMainWindow()
        }

        Start-Sleep -Milliseconds 300

        # Force close any remaining instances
        $settings = Get-Process -Name SystemSettings -ErrorAction SilentlyContinue
        if ($settings) {
            foreach ($proc in $settings) {
                $proc.Kill()
            }
        }

        # Wait until all Settings processes are gone
        while (Get-Process -Name SystemSettings -ErrorAction SilentlyContinue) {
            Start-Sleep -Milliseconds 150
        }
    }
    
    # Read the active theme
    $active = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes"
    if (-not ($active.CurrentTheme -ieq $themePath)) {
        return [pscustomobject]@{
            Success = $false
            Error   = "Theme file execution failed: $ThemePath, current theme in registry: $active.CurrentTheme"
        }
    }

    return [pscustomobject]@{
        Success = $true
        Error   = ""
    }
}

# Main function
function Set-DesktopSlideshow {
    $themePath = Get-WindowsDefaultThemePath
    if ($null -eq $themePath) {
        Write-Output "Could not find Windows default theme file (e.g. aero.theme)"
        return
    }
    
    $slideshowFolder = "$env:USERPROFILE\Pictures\SlideshowWallpapers"
    Create-SlideshowFolder -InputFolder $slideshowFolder
    Write-Output "Created slideshow folder: $slideshowFolder"
    
    $themeResult = New-SlideshowTheme `
        -InputThemePath $themePath `
        -IntervalMinutes 10 `
        -ImagesFolder $slideshowFolder `
        -OutputThemePath "$env:LOCALAPPDATA\Microsoft\Windows\Themes\Slideshow.theme"
        
    if (-not $themeResult.Success) {
        Write-Output "Failed to create new slideshow theme: $themeResult.Error"
        return
    }

    $newThemePath = $themeResult.Value
    Write-Output "Created slideshow theme file: $newThemePath"

    $applyResult = Apply-Theme -ThemePath $newThemePath
    if (-not $applyResult.Success) {
        Write-Output "Failed to apply slideshow theme file: $applyResult.Error"
    }
    Write-Output "Applied slideshow theme: $newThemePath"
}

###########################################################
#################### Personalization Tools ----------------
###########################################################

function Set-DarkMode {
    $regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

    reg add "$regPath" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
    reg add "$regPath" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
    
    Write-Output "Set Dark mode"
}

function Set-TransparencyOff {
    # --- 1. Master Personalization Switch ---
    # Works for both Win 10 and 11. Sets the 'Transparency effects' toggle to Off.
    $personalizePath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    reg add "$personalizePath" /v EnableTransparency /t REG_DWORD /d 0 /f

    # --- 2. DWM Composition Switch ---
    # Ensures the Desktop Window Manager reflects the change immediately.
    # On Windows 11, this is the key that synchronizes the 'Settings' app UI state.
    $dwmPath = "HKCU\Software\Microsoft\Windows\DWM"
    reg add "$dwmPath" /v Composition /t REG_DWORD /d 0 /f

    # --- 3. Accessibility Sync (Critical for 2025 Windows 11 UI) ---
    # In recent updates, transparency is also linked to Accessibility > Visual Effects.
    # Setting this ensures the toggle is OFF in BOTH Personalization and Accessibility menus.
    $accessibilityPath = "HKCU\Control Panel\Accessibility"
    reg add "$accessibilityPath" /v DynamicScrollbars /t REG_DWORD /d 0 /f
    
    Write-Output "Turned off transparency"
}

function Set-AutoAccentColor {
    # --- 1. ENABLE AUTOMATIC ACCENT COLOR ---
    # This sets "Pick an accent color from my background" to ON
    $dwmpPath = "HKCU\Control Panel\Desktop"
    reg add "$dwmpPath" /v AutoColorization /t REG_DWORD /d 1 /f

    # --- 2. DISABLE COLOR ON START, TASKBAR, AND ACTION CENTER ---
    # This ensures "Show accent color on Start and taskbar" is OFF
    $personalizePath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    reg add "$personalizePath" /v ColorPrevalence /t REG_DWORD /d 0 /f

    # --- 3. DISABLE COLOR ON TITLE BARS AND WINDOW BORDERS ---
    # This ensures "Show accent color on title bars and window borders" is OFF
    # In Windows 11, this specifically affects the 'AccentColorOnTitleBars' UI toggle
    $dwmxPath = "HKCU\Software\Microsoft\Windows\DWM"
    reg add "$dwmxPath" /v ColorPrevalence /t REG_DWORD /d 0 /f
    
    Write-Output "Enabled automatic accent color"
}

function Set-AutoHideTaskbar {
    # Enable taskbar auto-hide on Windows 10 and 11
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

    # Create the key if missing
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # If the Settings value doesn't exist, create a valid default 0x30-byte array
    try {
        $data = (Get-ItemProperty -Path $path -Name Settings -ErrorAction Stop).Settings
    }
    catch {
        # Default StuckRects3 Settings blob (taken from a clean Windows install)
        $data = [byte[]](
            0x30,0x00,0x00,0x00,0xFE,0xFF,0xFF,0xFF,
            0x03,0x00,0x00,0x00,0x03,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
        )
    }

    # Modify byte 8 (index 8) to enable auto-hide
    # 03 = auto-hide ON
    # 02 = auto-hide OFF
    $data[8] = 0x03

    # Write back the modified binary
    Set-ItemProperty -Path $path -Name Settings -Value $data

    # Broadcast WM_SETTINGCHANGE so the Settings UI updates
    $sig = @"
using System;
using System.Runtime.InteropServices;

public class NativeMethods {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@

    Add-Type $sig

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1A
    $SMTO_ABORTIFHUNG = 0x0002
    $result = [UIntPtr]::Zero

    [NativeMethods]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "TraySettings",
        $SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    ) | Out-Null
    
    Write-Output "Enabled auto-hide taskbar"
}

function Set-LockScreenSpotlight {
    # --- 1. Remove ALL slideshow settings
    # ==========================================

    $lockRoot = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen"
    $slideshowKey = "$lockRoot\Slideshow"

    # Remove slideshow mode flag
    Remove-ItemProperty -Path $lockRoot -Name "SlideshowEnabled" -ErrorAction SilentlyContinue

    # Remove slideshow folder keys
    if (Test-Path $slideshowKey) {
        Remove-Item -Path $slideshowKey -Recurse -Force
    }

    # Remove legacy slideshow folder keys
    $legacyKeys = @(
        "ImagesRootPath",
        "ImagesRootPath0",
        "ImagesRootPath1"
    )

    foreach ($key in $legacyKeys) {
        Remove-ItemProperty -Path $lockRoot -Name $key -ErrorAction SilentlyContinue
    }

    # --- 2. Remove Picture mode overrides
    # ==========================================

    Remove-ItemProperty -Path $lockRoot -Name "LockScreenImage" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $lockRoot -Name "LockScreenImagePath" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $lockRoot -Name "LockScreenImageUrl" -ErrorAction SilentlyContinue

    # --- 3. Enable Spotlight
    # ==========================================

    # Ensure lock screen key exists
    if (!(Test-Path $lockRoot)) {
        New-Item -Path $lockRoot -Force | Out-Null
    }

    # 1 = Spotlight
    Set-ItemProperty -Path $lockRoot `
        -Name "LockScreenType" `
        -Type DWord `
        -Value 1 `
        -Force

    # --- 4. Enable Spotlight content delivery
    #       (Spotlight will NOT activate unless these are correct)
    # ==========================================

    $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (!(Test-Path $cdm)) {
        New-Item -Path $cdm -Force | Out-Null
    }

    # Spotlight background ON
    Set-ItemProperty -Path $cdm -Name "RotatingLockScreenEnabled" -Type DWord -Value 1 -Force

    # Spotlight tips OFF
    Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Type DWord -Value 0 -Force

    # Required Spotlight content flags
    Set-ItemProperty -Path $cdm -Name "SubscribedContent-338387Enabled" -Type DWord -Value 1 -Force
    Set-ItemProperty -Path $cdm -Name "SubscribedContent-353694Enabled" -Type DWord -Value 1 -Force
    Set-ItemProperty -Path $cdm -Name "SubscribedContent-353696Enabled" -Type DWord -Value 1 -Force

    # Disable Windows welcome experience
    Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Type DWord -Value 0 -Force

    # --- 5. Remove Spotlight-blocking policy keys
    # ==========================================

    $policyKey = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
    if (!(Test-Path $policyKey)) {
        New-Item -Path $policyKey -Force | Out-Null
    }

    # These MUST be 0 for Spotlight to work
    Set-ItemProperty -Path $policyKey -Name "DisableWindowsSpotlightFeatures" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $policyKey -Name "DisableWindowsSpotlightOnActionCenter" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $policyKey -Name "DisableWindowsSpotlightOnSettings" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $policyKey -Name "DisableWindowsSpotlightWindowsWelcomeExperience" -Type DWord -Value 0 -Force
    Set-ItemProperty -Path $policyKey -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0 -Force

    # --- 6. Force Windows to reload lock screen settings
    # ==========================================

    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 1, True
    
    Write-Output "Set lock screen Spotlight"
}

###########################################################
#################### Third-Party Software------------------
###########################################################

# Internet connection required
function Install-AutoHideDesktopIcons {
    param(
        [int]$TimeoutSeconds
    )
    
    Write-Output "Starting AutoHideDesktopIcons installation..."
    
    # 1. Define Paths
    $installDir = "$env:LOCALAPPDATA\Programs\AutoHideDesktopIcons"
    $zipPath = "$installDir\AutoHideDesktopIcons.zip"
    $exePath = "$installDir\AutoHideDesktopIcons.exe"
    $iniPath = "$installDir\AutoHideDesktopIcons.ini"
    
    # 2. Uninstall if exists
    $proc = Get-Process AutoHideDesktopIcons -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc) {
        Stop-Process -Name AutoHideDesktopIcons -Force
    }
    if (Test-Path $installDir) {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # 3. Create directory
    if (!(Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir }

    # 4. Download the 64-bit portable version
    $downloadUrl = "https://www.softwareok.com/Download/AutoHideDesktopIcons.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # 5. Extract the file
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    Remove-Item $zipPath
    
    # 6. Configure
    $progPath = "HKCU:\Software\SoftwareOK\AutoHideDesktopIcons\Program"
    If (-not (Test-Path $progPath)) {
        New-Item -Path $progPath -Force | Out-Null
    }
    New-ItemProperty -Path $progPath -Name "auto_hide_icons_sec"      -Value "$TimeoutSeconds"  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "m_wallpaper_color"        -Value "-1" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "show_icons_by_contextmenu" -Value "1" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "show_icons_by_l_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "show_icons_by_m_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "show_icons_by_r_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "start_tray"               -Value "1"  -PropertyType String -Force | Out-Null
    
    # 7. Add to Startup
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    New-ItemProperty -Path $registryPath -Name "AutoHideDesktopIcons" -Value $exePath -PropertyType "String" -Force | Out-Null

    # 8. Start the application now
    Start-Process -FilePath $exePath
    
    Write-Output "Installation completed, launched AutoHideDesktopIcons"
}

# Internet connection required
function Install-AutoHideMouseCursor {
    param(
        [int]$TimeoutSeconds
    )
    
        Write-Output "Starting AutoHideMouseCursor installation..."
    
    # 1. Define Paths
    $installDir = "$env:LOCALAPPDATA\Programs\AutoHideMouseCursor"
    $zipPath = "$installDir\AutoHideMouseCursor.zip"
    $exePath = "$installDir\AutoHideMouseCursor.exe"
    $iniPath = "$installDir\AutoHideMouseCursor.ini"
    
    # 2. Uninstall if exists
    $proc = Get-Process AutoHideMouseCursor -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc) {
        Stop-Process -Name AutoHideMouseCursor -Force
    }
    if (Test-Path $installDir) {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # 3. Create directory
    if (!(Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir }

    # 4. Download the 64-bit portable version
    $downloadUrl = "https://www.softwareok.com/Download/AutoHideMouseCursor.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # 5. Extract the file
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    Remove-Item $zipPath
    
    # 6. Configure
    $progPath = "HKCU:\Software\SoftwareOK\Mocro-Staff\AutoHideMouseCursor\Program"
    If (-not (Test-Path $progPath)) {
        New-Item -Path $progPath -Force | Out-Null
    }
    New-ItemProperty -Path $progPath -Name "auto_hide_icons_sec"      -Value "$TimeoutSeconds"  -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "hidden_when_you_press_an_key_on_the_keyboard"        -Value "-1" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $progPath -Name "start_tray"               -Value "1"  -PropertyType String -Force | Out-Null
    
    # 7. Add to Startup
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    New-ItemProperty -Path $registryPath -Name "AutoHideMouseCursor" -Value $exePath -PropertyType "String" -Force | Out-Null

    # 8. Start the application now
    Start-Process -FilePath $exePath
    
    Write-Output "Installation completed, launched AutoHideMouseCursor"
}

###########################################################
#################### Other Tools --------------------------
###########################################################

function Join-Explorer {
    # Capture the original explorer PID (if running)
    $old = Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -First 1
    $oldPid = $old?.Id

    if ($old) {
        $oldPid = $old.Id
    } else {
        $oldPid = $null
    }

    # If explorer is running, stop it
    if ($oldPid) {
        Stop-Process -Id $oldPid -Force
    }

    # Wait for either:
    # 1. Explorer fully gone
    # 2. A *new* Explorer PID (auto-restart)
    $deadline = [datetime]::Now.AddSeconds(5)
    while ([datetime]::Now -lt $deadline) {
        $current = Get-Process explorer -ErrorAction SilentlyContinue

        if (-not $current) {
            # Explorer is fully gone — break and allow manual restart
            break
        }

        if ($oldPid -and ($current.Id -ne $oldPid)) {
            # Auto-restart detected — wait for stabilization
            Start-Sleep -Seconds 1
            return
        }

        Start-Sleep -Milliseconds 150
    }

    # If Explorer is not running, start it manually
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }

    # Wait until explorer is fully initialized
    while (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Sleep -Milliseconds 150
    }

    # Give the shell a moment to bring up the desktop/taskbar
    Start-Sleep -Seconds 1
    
    Write-Output "Explorer process restarted"
}

###########################################################
#################### Perform Customizations ---------------
###########################################################

Set-DesktopSlideshow

Set-DarkMode
Set-TransparencyOff
Set-AutoAccentColor
Set-AutoHideTaskbar
Set-LockScreenSpotlight

Join-Explorer

Install-AutoHideDesktopIcons 5
Install-AutoHideMouseCursor 5
