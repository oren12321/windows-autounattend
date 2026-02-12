param(
    [string]$Mode  # "FirstUser" or "PerUser"
)

$logFile = "$PSScriptRoot\..\Logs\UserSetup.log"

# Logging helper
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Out-File $logFile -Append
}

<#
###############################################################
<#  
    Waits for Windows first‑logon initialization to finish before applying HKCU tweaks.
    Includes:
      - ShellExperienceHost readiness
      - ContentDeliveryManager completion
      - CloudExperienceHostBroker readiness
      - Explorer readiness
      - %LOCALAPPDATA%\Packages present
    Each condition has a timeout to prevent hangs.
#>

function Wait-Until {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Condition,

        [int]$TimeoutSeconds = 300,   # 5 minutes max
        [int]$IntervalSeconds = 2,
        [string]$Description = "Unnamed condition"
    )

    Write-Output "Waiting for: $Description (timeout: $TimeoutSeconds seconds)"

    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $end) {

        if (& $Condition) {
            Write-Output "Condition met: $Description"
            return $true
        }

        Write-Output "Still waiting for: $Description..."
        Start-Sleep -Seconds $IntervalSeconds
    }

    Write-Output "Timeout reached for: $Description — continuing anyway"
    return $false
}

& {
    # ---------------------------------------------------------
    # CONDITION 1 — Core Shell Host (Agnostic)
    # ---------------------------------------------------------

    Wait-Until `
        -Description "Any Shell/Start Host to start" `
        -Condition {
            # Check for the Win11/Modern process OR the legacy Win10 process
            (Get-Process StartMenuExperienceHost -ErrorAction SilentlyContinue) -or `
            (Get-Process ShellExperienceHost -ErrorAction SilentlyContinue)
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 2 — ContentDeliveryManager (CDM) background tasks finished
    # ---------------------------------------------------------

    Wait-Until `
        -Description "ContentDeliveryManager background tasks to finish" `
        -Condition {
            -not (
                Get-Process -Name "backgroundTaskHost" -ErrorAction SilentlyContinue |
                Where-Object { $_.Path -like "*ContentDeliveryManager*" }
            )
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 3 — Cloud/Modern Host Broker (Agnostic)
    # ---------------------------------------------------------

    # We don't pre-capture $brokerProc here. We check inside the condition.
    Wait-Until `
        -Description "CloudExperienceHostBroker stabilization" `
        -Condition {
            $p = Get-Process CloudExperienceHostBroker -ErrorAction SilentlyContinue
            # SUCCESS IF: 
            # 1. The process doesn't exist at all (Windows 11 / already finished)
            # 2. OR it exists but is no longer suspended (actually working)
            (-not $p) -or ($p.Threads.WaitReason -ne 'Suspended')
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 4 — explorer is running and stable
    # ---------------------------------------------------------

    Wait-Until `
        -Description "explorer.exe to start" `
        -Condition {
            Get-Process explorer -ErrorAction SilentlyContinue
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 5 — Packages folder is present
    # ---------------------------------------------------------

    Wait-Until `
        -Description "$env:LOCALAPPDATA\Packages to be present" `
        -Condition {
            Test-Path "$env:LOCALAPPDATA\Packages"
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 6 — Dynamic Session Stability Flag
    # ---------------------------------------------------------
    # Ensures the specific session for THIS user is marked stable by Windows.
    $currentSessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId

    Wait-Until `
        -Description "Explorer SessionInfo flag for Session $currentSessionId" `
        -Condition {
            Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\$currentSessionId"
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 7 — Start Experience Host is ACTIVE (Not Suspended)
    # ---------------------------------------------------------
    # This is the most critical check for UI mods (Taskbar/Start).
    Wait-Until `
        -Description "StartMenuExperienceHost to be active (unsuspended)" `
        -Condition {
            $proc = Get-Process "StartMenuExperienceHost" -ErrorAction SilentlyContinue
            
            # 1. If it doesn't exist YET, keep waiting (don't return $true!)
            if (-not $proc) { return $false }
            
            # 2. If it exists, check how long it's been running
            $upTimeSec = (New-TimeSpan -Start $proc.StartTime -End (Get-Date)).TotalSeconds
            
            # 3. STABLE SESSION BYPASS:
            # If the process is older than 60s, it's already "settled" (like in your current test).
            # We don't care if it's suspended now; it's already done its first-run work.
            if ($upTimeSec -gt 60) { return $true }

            # 4. FIRST LOGON PROTECTION:
            # If it's a brand new process (< 60s old), we MUST wait until it's NOT suspended.
            # This ensures we don't write to HKCU while the UI is still "waking up".
            $isSuspended = $proc.Threads.WaitReason -contains 'Suspended'
            
            return (-not $isSuspended)
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2
    
    # ---------------------------------------------------------
    # CONDITION 8 — Wait for Desktop to be Visible (OOBE Finished)
    # ---------------------------------------------------------
    # Windows sets 'FirstLogonAnim' to 0 once the "Hi" screen ends and the desktop appears.
    Wait-Until `
        -Description "Desktop to be visible (FirstLogonAnim = 0)" `
        -Condition {
            $animStatus = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "FirstLogonAnim" -ErrorAction SilentlyContinue
            # If the value doesn't exist, we assume it's an existing profile/stable session.
            # If it is 0, the animation has ended and the desktop is visible.
            ($null -eq $animStatus) -or ($animStatus.FirstLogonAnim -eq 0)
        } `
        -TimeoutSeconds 120 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # CONDITION 9 — Shell "IsInitialized" Check
    # ---------------------------------------------------------
    Wait-Until `
        -Description "Shell to report 'IsInitialized' flag" `
        -Condition {
            # This specific registry value is flipped by Explorer once the desktop is interactive.
            $init = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShellInitialized" -ErrorAction SilentlyContinue
            
            # If the key doesn't exist (older Win10), fallback to checking the SessionInfo path again
            if ($null -eq $init) {
                return Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\$([System.Diagnostics.Process]::GetCurrentProcess().SessionId)"
            }
            
            return ($init.ShellInitialized -eq 1)
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # ---------------------------------------------------------
    # FINAL STABILIZATION
    # ---------------------------------------------------------
    Write-Output "All stability markers met. Waiting 10s for final background flushes..."
    Start-Sleep -Seconds 10
    
} *>&1 | Out-String -Width 1KB -Stream >> "$PSScriptRoot\..\Logs\UserSetup.log";
###############################################################
#>

Write-Log "Starting UserSetup.ps1 with Mode='$Mode'"

switch ($Mode) {

    "FirstUser" {
        Write-Log "Executing FirstUser mode"
    
        try {
            # Things ONLY the first user should get
            # Example: OEM branding, one-time app installs, etc.
            & "$PSScriptRoot\UserSetup.FirstUser.ps1"
        }
        catch {
            Write-Log "ERROR in FirstUser script: $_"
        }
    }

    "PerUser" {
        Write-Log "Executing PerUser mode"
    
        try {
            # Things EVERY user should get
            # Example: Explorer defaults, Taskbar tweaks, Start menu tweaks
            & "$PSScriptRoot\UserSetup.PerUser.ps1"
        }
        catch {
            Write-Log "ERROR in PerUser script: $_"
        }
    }
    
    default {
        Write-Log "WARNING: Invalid mode '$Mode'. Expected 'FirstUser' or 'PerUser'."
        return
    }
}

Write-Log "UserSetup.ps1 finished"