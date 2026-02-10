$PerformanceEntries = @(
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        Name        = "AppCaptureEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable Game DVR app capture for new users"
    },
    @{
        Path        = "HKCU:\Control Panel\Mouse"
        Name        = "MouseSpeed"
        Type        = "String"
        Value       = 0
        Description = "Set mouse speed"
    },
    @{
        Path        = "HKCU:\Control Panel\Mouse"
        Name        = "MouseThreshold1"
        Type        = "String"
        Value       = 0
        Description = "Set mouse threshold 1"
    },
    @{
        Path        = "HKCU:\Control Panel\Mouse"
        Name        = "MouseThreshold2"
        Type        = "String"
        Value       = 0
        Description = "Set mouse threshold 2"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\GameBar"
        Name        = "AutoGameModeEnabled"
        Type        = "DWord"
        Value       = 1
        Description = "Optimize your PC for play by turning things off in the background"
    },
    @{
        Path        = "HKCU:\Control Panel\Mouse"
        Name        = "MouseSpeed"
        Type        = "String"
        Value       = "0"
        Description = "Adjust cursor speed based on movement velocity (mouse acceleration). Most competitive gamers disable this for consistent aiming in FPS games"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
        Name        = "StartupDelayInMSec"
        Type        = "DWord"
        Value       = 10000
        Description = "Delay startup applications by 10 seconds after boot to improve initial system responsiveness"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences"
        Name        = "WholeFileSystem"
        Type        = "DWord"
        Value       = 0
        Description = "Search your entire file system instead of only indexed locations"
    },
    @{
        Path        = "HKCU:\Control Panel\Desktop"
        Name        = "JPEGImportQuality"
        Type        = "DWord"
        Value       = 100
        Description = "Allow Windows to compress wallpapers to save disk space and improve performance"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        Name        = "DirectXUserGlobalSettings"
        Type        = "String"
        Value       = "SwapEffectUpgradeEnable=1;"
        Description = "Reduce latency and use advanced features in compatible games by using DirectX flip presentation model"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        Name        = "VRROptimizeEnable"
        Type        = "DWord"
        Value       = 0
        Description = "Enable VRR optimizations for smoother gameplay"
    },
    @{
        Path        = "HKCU:\System\GameConfigStore"
        Name        = "GameDVR_FSEBehaviorMode"
        Type        = "DWord"
        Value       = 0
        Description = "Allow Windows to optimize games running in fullscreen mode"
    },
    @{
        Path        = "HKCU:\System\GameConfigStore"
        Name        = "GameDVR_Enabled"
        Type        = "DWord"
        Value       = 0
        Description = "Disable Game DVR to reduce CPU/GPU usage"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\GameBar"
        Name        = "UseNexusForGameBarEnabled"
        Type        = "DWord"
        Value       = 0
        Description = "Allow your Xbox/compatible controller to open Game Bar with the Xbox button"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\GameBar"
        Name        = "ShowStartupPanel"
        Type        = "DWord"
        Value       = 0
        Description = "Show tips and hints about Game Bar features when opening the overlay"
    }
)