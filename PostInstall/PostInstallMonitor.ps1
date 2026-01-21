$logFile = Join-Path $PSScriptRoot 'PostInstallMonitor.log'

# Logging helper
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Out-File $logFile -Append
}

function Invoke-PostInstallMonitor {
    param()

    Write-Log "=== PostInstallMonitor started ==="

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'
    $HKLM = 'HKLM:\Software\MyCompany\PostInstall'
    $ActionScript = Join-Path $PSScriptRoot 'PostInstallAction.ps1'

    # Load action function
    . (Join-Path $PSScriptRoot 'PostInstallAction.ps1')

    $maxWaitSeconds = 300
    $waitInterval   = 5
    $elapsed        = 0

    #
    # Wait for HKCU key to appear
    #
    Write-Log "Waiting for HKCU key: $HKCU"
    while (-not (Test-Path $HKCU) -and $elapsed -lt $maxWaitSeconds) {
        Start-Sleep -Seconds $waitInterval
        $elapsed += $waitInterval
    }

    if (-not (Test-Path $HKCU)) {
        Write-Log "HKCU key did not appear within timeout. Exiting."
        return
    }

    Write-Log "HKCU key detected."

    #
    # Wait for SetupComplete = 1
    #
    $elapsed = 0
    Write-Log "Waiting for SetupComplete = 1"
    do {
        $state = Get-ItemProperty -Path $HKCU
        $setupComplete = $state.SetupComplete

        if ($setupComplete -ne 1) {
            Start-Sleep -Seconds $waitInterval
            $elapsed += $waitInterval
        }
    }
    while ($setupComplete -ne 1 -and $elapsed -lt $maxWaitSeconds)

    if ($setupComplete -ne 1) {
        Write-Log "SetupComplete did not reach 1 within timeout. Exiting."
        return
    }

    Write-Log "SetupComplete = 1 detected."

    #
    # Read state
    #
    $state          = Get-ItemProperty -Path $HKCU
    $actionRequired = $state.ActionRequired
    $actionCompleted= $state.ActionCompleted
    $setupCycle     = $state.SetupCycle

    Write-Log "State: SetupCycle=$setupCycle, ActionRequired=$actionRequired, ActionCompleted=$actionCompleted"

    #
    # Determine target cycle
    #
    $targetCycle = 1
    if (Test-Path $HKLM) {
        $lm = Get-ItemProperty -Path $HKLM -ErrorAction SilentlyContinue
        if ($lm -and $lm.TargetCycle) {
            $targetCycle = $lm.TargetCycle
        }
    }

    Write-Log "TargetCycle = $targetCycle"

    #
    # If user cycle is behind, bump it
    #
    if ($setupCycle -lt $targetCycle) {
        Write-Log "SetupCycle ($setupCycle) is behind TargetCycle ($targetCycle). Updating user state."

        Set-ItemProperty -Path $HKCU -Name SetupCycle      -Value $targetCycle
        Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1
        Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0

        $actionRequired  = 1
        $actionCompleted = 0

        Write-Log "User state updated: SetupCycle=$targetCycle, ActionRequired=1, ActionCompleted=0"
    }

    #
    # If no action required or already completed, exit
    #
    if ($actionRequired -ne 1 -or $actionCompleted -eq 1) {
        Write-Log "No action required (ActionRequired=$actionRequired, ActionCompleted=$actionCompleted). Exiting."
        return
    }

    #
    # Execute action script
    #
    if (Test-Path $ActionScript) {
        Write-Log "Executing PostInstallAction.ps1"
        Invoke-PostInstallAction
        Write-Log "PostInstallAction.ps1 completed."
    }
    else {
        Write-Log "Action script not found: $ActionScript"
    }

    Write-Log "=== PostInstallMonitor finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-PostInstallMonitor
}