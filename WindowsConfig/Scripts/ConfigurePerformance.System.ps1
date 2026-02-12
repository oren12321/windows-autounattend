. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        Name = "LetAppsRunInBackground"
        Type = "DWord"
        Value = 0
        Description = "Controls whether Windows allows apps to run background processes."
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
        Name = "AllowStorageSenseGlobal"
        Type = "DWord"
        Value = 0
        Description = "Enables or disables the Storage Sense automatic cleanup feature."
    },
    @{
        Path = "HKLM:\System\CurrentControlSet\Control\PriorityControl"
        Name = "Win32PrioritySeparation"
        Type = "DWord"
        Value = 38
        Description = "Adjusts how Windows prioritizes CPU time between foreground and background tasks."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Name = "SystemResponsiveness"
        Type = "DWord"
        Value = 10
        Description = "Defines how much system resources are reserved for background multimedia tasks."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "Priority"
        Type = "DWord"
        Value = 6
        Description = "Sets the CPU scheduling priority level for game-related processes."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "Scheduling Category"
        Type = "String"
        Value = 'High'
        Description = "Specifies the scheduling category assigned to game tasks."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "GPU Priority"
        Type = "DWord"
        Value = 8
        Description = "Determines the GPU scheduling priority for game workloads."
    },
    @{
        Path = "HKLM:\System\CurrentControlSet\Control\GraphicsDrivers"
        Name = "HwSchMode"
        Type = "DWord"
        Value = 2
        Description = "Enables or configures hardware-accelerated GPU scheduling."
    },
    @{
        Path = "HKLM:\Software\NVIDIA Corporation\Global\FTS"
        Name = "EnableGR535"
        Type = "DWord"
        Value = 0
        Description = "Toggles NVIDIA’s legacy image-sharpening feature."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Name = "NetworkThrottlingIndex"
        Type = "DWord"
        Value = 10
        Description = "Controls Windows’ network throttling behavior for multimedia and gaming traffic."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Name = "TcpAckFrequency"
        Type = "DWord"
        Value = 2
        Description = "Sets how frequently TCP sends acknowledgment packets."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Name = "TCPNoDelay"
        Type = "DWord"
        Value = 0
        Description = "Enables or disables Nagle’s algorithm for TCP packet batching."
    },
    @{
        Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\GameConfigStore"
        Name = "AllowGameDVR"
        Type = "DWord"
        Value = 0
        Description = "Controls whether the Xbox Game Bar is allowed to record gameplay and capture screenshots."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control"
        Name = "ServicesPipeTimeout"
        Type = "DWord"
        Value = 30000
        Description = "Defines how long Windows waits for services to start before timing out."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Controls whether the SysMain service (Superfetch) is enabled for application preloading."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
        Name = "EnablePrefetcher"
        Type = "DWord"
        Value = 0
        Description = "Enables or disables Windows Prefetching for faster application and boot loading."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls whether the Windows Search indexing service is enabled."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Determines whether the Print Spooler service is enabled to manage print jobs."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Connected User Experiences and Telemetry service for diagnostic data collection."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\PcaSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages the Program Compatibility Assistant service that detects compatibility issues."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WerSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Windows Error Reporting service responsible for crash data collection."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages the Geolocation service used by apps to access device location."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\RetailDemo"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Retail Demo service used for in‑store demonstration mode."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\wisvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages Windows Insider Program services and preview build functionality."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\PhoneSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Phone Service responsible for telephony features on Windows devices."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WalletService"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages the Microsoft Wallet service for payment and NFC features."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SCardSvr"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Smart Card service used for authentication with smart card devices."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\ScDeviceEnum"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Handles enumeration of smart card devices for authentication purposes."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SCPolicySvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages smart card security policies for authentication operations."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\MapsBroker"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Maps Broker service that provides access to offline maps."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Fax"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Controls the Fax service used for sending and receiving faxes."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WMPNetworkSvc"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Manages network sharing of Windows Media Player libraries."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\MixedRealityOpenXRSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Runs the OpenXR service required for Windows Mixed Reality applications."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\icssvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Controls the Internet Connection Sharing service used to share a network connection with other devices."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SmsRouter"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages routing of SMS messages for devices that support messaging features."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WpcMonSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Runs the Family Safety monitoring service for parental control features."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SEMgrSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Handles secure element management for NFC and payment-related functionality."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\svsvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Runs the Spot Verifier service to check for potential file system corruption."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages VPN, dial‑up, and remote access connections."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\RasAuto"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Automatically establishes remote connections when applications access remote resources."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\TermService"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Enables Remote Desktop connections to the computer."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SessionEnv"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Manages Remote Desktop session settings and environment configuration."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\UmRdpService"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Provides device redirection support for Remote Desktop sessions."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\BITS"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Handles background file transfers such as Windows Update downloads."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\XblAuthManager"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Provides authentication services required for Xbox Live functionality."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\XblGameSave"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Manages cloud save synchronization for Xbox-enabled games."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\XboxNetApiSvc"
        Name = "Start"
        Type = "DWord"
        Value = 4
        Description = "Supports Xbox Live networking features including multiplayer connectivity."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\WbioSrvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Runs the Windows Biometric Service for fingerprint and facial recognition."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\TabletInputService"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Provides touch keyboard, handwriting, and pen input functionality."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SensrSvc"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Monitors system sensors such as orientation and ambient light."
    },
    @{
        Path = "HKLM:\SYSTEM\CurrentControlSet\Services\SensorDataService"
        Name = "Start"
        Type = "DWord"
        Value = 3
        Description = "Supplies sensor data from hardware sensors to applications."
    },
    @{
        Path        = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Name        = "LongPathsEnabled"
        Type        = "DWord"
        Value       = 1
        Description = "Enables support for file paths with up to 32,767 characters instead of the traditional 260-character limit"
    }
)
Apply-RegistryBatch $entries

$scheduledTasks = @(
    @{ TN="\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"; Action="/Disable"; Desc="Evaluates system and application compatibility for Windows upgrades." },
    @{ TN="\Microsoft\Windows\Application Experience\ProgramDataUpdater"; Action="/Disable"; Desc="Updates the system’s program compatibility data." },
    @{ TN="\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"; Action="/Disable"; Desc="Aggregates and sends Customer Experience Improvement Program telemetry." },
    @{ TN="\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"; Action="/Disable"; Desc="Collects telemetry related to USB device usage." },
    @{ TN="\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"; Action="/Disable"; Desc="Gathers disk health and diagnostic information." },
    @{ TN="\Microsoft\Windows\Feedback\Siuf\DmClient"; Action="/Disable"; Desc="Collects user feedback and diagnostic data for Microsoft." },
    @{ TN="\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"; Action="/Disable"; Desc="Downloads configuration data for feedback and diagnostic scenarios." },
    @{ TN="\Microsoft\Windows\Windows Error Reporting\QueueReporting"; Action="/Disable"; Desc="Queues and processes Windows error and crash reports." },
    @{ TN="\Microsoft\Windows\PI\Sqm-Tasks"; Action="/Disable"; Desc="Collects software quality and reliability metrics." },
    @{ TN="\Microsoft\Windows\Application Experience\MareBackup"; Action="/Disable"; Desc="Backs up data used by Microsoft Assisted Recovery." },
    @{ TN="\Microsoft\Windows\Application Experience\StartupAppTask"; Action="/Disable"; Desc="Monitors startup applications for compatibility and diagnostics." },
    @{ TN="\Microsoft\Windows\Application Experience\PcaPatchDbTask"; Action="/Disable"; Desc="Updates the Program Compatibility Assistant’s patch database." },
    @{ TN="\Microsoft\Windows\Maps\MapsUpdateTask"; Action="/Disable"; Desc="Updates offline map data for the Maps application." },
    @{ TN="\Microsoft\Windows\Autochk\Proxy"; Action="/Disable"; Desc="Runs scheduled disk check and diagnostic tasks." },
    @{ TN="\Microsoft\Windows\Shell\FamilySafetyMonitor"; Action="/Disable"; Desc="Monitors activity for Microsoft Family Safety features." },
    @{ TN="\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"; Action="/Disable"; Desc="Analyzes system power usage for efficiency diagnostics." }
)

Write-Output "Applying scheduled task settings..."
$processedCount = 0
foreach ($task in $scheduledTasks) {
    try {
        $result = & cmd.exe /c "schtasks /Change /TN `"$($task.TN)`" $($task.Action)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "$($task.Desc)"
            $processedCount++
        } else {
            Write-Output "Task command failed for: $($task.Desc)"
        }
    } catch {
        Write-Output "Failed to process task: $($task.Desc) - $($_.Exception.Message)"
    }
}
Write-Output "Processed $processedCount scheduled task settings"

fsutil.exe behavior set disableLastAccess 1;
