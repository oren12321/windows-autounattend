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
    # CONDITION 1 — ShellExperienceHost is running and stable
    # ---------------------------------------------------------

    Wait-Until `
        -Description "ShellExperienceHost.exe to start" `
        -Condition {
            Get-Process ShellExperienceHost -ErrorAction SilentlyContinue
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # Give it a moment to finish writing theme defaults
    Write-Output "ShellExperienceHost detected — waiting 5 seconds for stabilization..."
    Start-Sleep -Seconds 5


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
    # CONDITION 3 — CloudExperienceHostBroker is running and stable
    # ---------------------------------------------------------

    Wait-Until `
        -Description "CloudExperienceHostBroker.exe to start" `
        -Condition {
            Get-Process CloudExperienceHostBroker -ErrorAction SilentlyContinue
        } `
        -TimeoutSeconds 60 `
        -IntervalSeconds 2

    # Give it a moment to finish writing theme defaults
    Write-Output "CloudExperienceHostBroker detected — waiting 5 seconds for stabilization..."
    Start-Sleep -Seconds 5

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

    # Give it a moment to finish writing theme defaults
    Write-Output "explorer detected — waiting 5 seconds for stabilization..."
    Start-Sleep -Seconds 5

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

    # Give it a moment to finish writing theme defaults
    Write-Output "$env:LOCALAPPDATA\Packages detected — waiting 5 seconds for stabilization..."
    Start-Sleep -Seconds 5
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