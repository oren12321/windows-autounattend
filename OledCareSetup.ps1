################# OLED CARE #######################
###################################################

################# DARK MODE -----------------------

# 1. PATH DEFINITION (Changed to HKCU for the active profile)
$regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

# 2. APPLY MODIFICATIONS (Using reg.exe for stability)
# No loading/unloading required for HKCU
reg add "$regPath" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "$regPath" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f

# 3. THEME SYNC (Optional for current session, but ensures UI settings match)
if ([Environment]::OSVersion.Version.Build -ge 22000) {
    $themeKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes"
    reg add "$themeKey" /v CurrentTheme /t REG_SZ /d "C:\Windows\Resources\Themes\dark.theme" /f
}

Write-Host "Dark Mode applied to the CURRENT session. Restart Explorer or log out to see full effect."

# Restart Explorer to apply immediately
Stop-Process -Name explorer -Force

################# TRANSPARANCY OFF ----------------

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

Write-Host "Transparency disabled across Windows 10/11 UI. Refreshing shell..."

# Restart Explorer to apply immediately
Stop-Process -Name explorer -Force

################# AUTO ACCENT COLOR ---------------

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

Write-Host "Automatic accent color enabled. Surface coloring disabled."

# Restart Explorer to apply immediately
Stop-Process -Name explorer -Force

################# ICONS ---------------------------
# 1. Define Paths
$installDir = "$env:LOCALAPPDATA\Programs\AutoHideDesktopIcons"
$zipPath = "$installDir\AutoHideDesktopIcons.zip"
$exePath = "$installDir\AutoHideDesktopIcons.exe"
$iniPath = "$installDir\AutoHideDesktopIcons.ini"

# 2. Create directory
if (!(Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir }

# 3. Download the 64-bit portable version
$downloadUrl = "https://www.softwareok.com/Download/AutoHideDesktopIcons.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

# 4. Extract the file
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath

$progPath = "HKCU:\Software\SoftwareOK\AutoHideDesktopIcons\Program"

If (-not (Test-Path $progPath)) {
    New-Item -Path $progPath -Force | Out-Null
}

# Create/update values (all REG_SZ)

New-ItemProperty -Path $progPath -Name "auto_hide_icons_sec"      -Value "5"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "m_wallpaper_color"        -Value "-1" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "show_icons_by_contextmenu" -Value "1" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "show_icons_by_l_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "show_icons_by_m_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "show_icons_by_r_mouse"    -Value "1"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "start_tray"               -Value "1"  -PropertyType String -Force | Out-Null


# 6. Add to Startup (Registry method)
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
New-ItemProperty -Path $registryPath -Name "AutoHideDesktopIcons" -Value $exePath -PropertyType "String" -Force | Out-Null

# 7. Start the application now
Start-Process -FilePath $exePath

################# CURSOR ---------------------------
# 1. Define Paths
$installDir = "$env:LOCALAPPDATA\Programs\AutoHideMouseCursor"
$zipPath = "$installDir\AutoHideMouseCursor.zip"
$exePath = "$installDir\AutoHideMouseCursor.exe"
$iniPath = "$installDir\AutoHideMouseCursor.ini"

# 2. Create directory
if (!(Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir }

# 3. Download the 64-bit portable version
$downloadUrl = "https://www.softwareok.com/Download/AutoHideMouseCursor.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

# 4. Extract the file
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath

$progPath = "HKCU:\Software\SoftwareOK\Mocro-Staff\AutoHideMouseCursor\Program"

If (-not (Test-Path $progPath)) {
    New-Item -Path $progPath -Force | Out-Null
}

# Create/update values (all REG_SZ)

New-ItemProperty -Path $progPath -Name "auto_hide_icons_sec"      -Value "5"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "hidden_when_you_press_an_key_on_the_keyboard"    -Value "1"  -PropertyType String -Force | Out-Null
New-ItemProperty -Path $progPath -Name "start_tray"               -Value "1"  -PropertyType String -Force | Out-Null

# 6. Add to Startup (Registry method)
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
New-ItemProperty -Path $registryPath -Name "AutoHideMouseCursor" -Value $exePath -PropertyType "String" -Force | Out-Null

# 7. Start the application now
Start-Process -FilePath $exePath

################# AUTO HIDE TASKBAR -----------------

# Enable taskbar auto-hide on Windows 10 and 11
# Fully compatible with fresh installations

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

# Restart Explorer to apply immediately
Stop-Process -Name explorer -Force

################# SLIDESHOW ---------------------------------------

# ==========================================
# 1. Locate the currently active theme file
# ==========================================
$themeRegPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes"
$currentTheme  = (Get-ItemProperty $themeRegPath).CurrentTheme

if (-not (Test-Path $currentTheme)) {
    Write-Host "Could not find current theme file: $currentTheme"
    exit
}

# Read theme file using auto-detected encoding
$themeLines = Get-Content $currentTheme

# ==========================================
# 2. Prepare slideshow folder
# ==========================================
$slideshowPath = "$env:USERPROFILE\Pictures\SlideshowWallpapers"
if (!(Test-Path $slideshowPath)) {
    New-Item -ItemType Directory -Path $slideshowPath | Out-Null
}

# Copy default wallpaper if folder is empty
if (-not (Get-ChildItem $slideshowPath -File -ErrorAction SilentlyContinue)) {
    $possibleWallpapers = @(
        "C:\Windows\Web\Wallpaper\Windows\img0.jpg",
        "C:\Windows\Web\Wallpaper\Windows\img0.png",
        "C:\Windows\Web\Wallpaper\Theme1\img1.jpg",
        "C:\Windows\Web\Wallpaper\Theme1\img1.png"
    )
    $defaultWallpaper = $possibleWallpapers | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($defaultWallpaper) {
        Copy-Item $defaultWallpaper "$slideshowPath\DefaultWallpaper.jpg" -Force
    }
}

# ==========================================
# 3. Remove existing [Slideshow] block (if any)
# ==========================================
$cleanedLines = New-Object System.Collections.Generic.List[string]
$inSlideshow = $false

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

# ==========================================
# 4. Append new slideshow block
# ==========================================
$cleanedLines.Add("")
$cleanedLines.Add("[Slideshow]")
$cleanedLines.Add("Interval=600000")
$cleanedLines.Add("Shuffle=1")
$cleanedLines.Add("ImagesRootPath=$slideshowPath")

# ==========================================
# 5. Save as a new theme file (UTF‑16 LE)
# ==========================================
$themeDir = "$env:LOCALAPPDATA\Microsoft\Windows\Themes"
if (!(Test-Path $themeDir)) {
    New-Item -ItemType Directory -Path $themeDir | Out-Null
}

$newThemePath = Join-Path $themeDir "Slideshow.theme"
$cleanedLines | Set-Content -Path $newThemePath -Encoding Unicode

Write-Host "New theme written to: $newThemePath"

# ==========================================
# 6. Apply the new theme
# ==========================================
Start-Process $newThemePath

# Wait briefly for Settings to launch
Start-Sleep -Seconds 1

# Try to close the Settings window
$settings = Get-Process -Name SystemSettings -ErrorAction SilentlyContinue
if ($settings) {
    $settings.CloseMainWindow() | Out-Null
    Start-Sleep -Milliseconds 300

    # If it didn't close, force it
    if (!$settings.HasExited) {
        $settings.Kill()
    }
}

################ LOCK SCREEN SPOTLIGHT --------------------

# ==========================================
# 1. Remove ALL slideshow settings
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

# ==========================================
# 2. Remove Picture mode overrides
# ==========================================

Remove-ItemProperty -Path $lockRoot -Name "LockScreenImage" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $lockRoot -Name "LockScreenImagePath" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $lockRoot -Name "LockScreenImageUrl" -ErrorAction SilentlyContinue

# ==========================================
# 3. Enable Spotlight
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

# ==========================================
# 4. Enable Spotlight content delivery
#    (Spotlight will NOT activate unless these are correct)
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

# ==========================================
# 5. Remove Spotlight-blocking policy keys
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

# ==========================================
# 6. Force Windows to reload lock screen settings
# ==========================================

RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 1, True

Write-Host "Windows Spotlight is now enabled with no tips or suggestions."