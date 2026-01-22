function Write-Timestamped {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp | $Message"
}

function Invoke-PostInstallMonitor {
    param()

    Write-Timestamped "=== PostInstallMonitor started ==="

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
    Write-Timestamped "Waiting for HKCU key: $HKCU"
    while (-not (Test-Path $HKCU) -and $elapsed -lt $maxWaitSeconds) {
        Start-Sleep -Seconds $waitInterval
        $elapsed += $waitInterval
    }

    if (-not (Test-Path $HKCU)) {
        Write-Timestamped "HKCU key did not appear within timeout. Exiting."
        return
    }

    Write-Timestamped "HKCU key detected."

    #
    # Wait for SetupComplete = 1
    #
    $elapsed = 0
    Write-Timestamped "Waiting for SetupComplete = 1"
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
        Write-Timestamped "SetupComplete did not reach 1 within timeout. Exiting."
        return
    }

    Write-Timestamped "SetupComplete = 1 detected."

    #
    # Read state
    #
    $state          = Get-ItemProperty -Path $HKCU
    $actionRequired = $state.ActionRequired
    $actionCompleted= $state.ActionCompleted
    $setupCycle     = $state.SetupCycle

    Write-Timestamped "State: SetupCycle=$setupCycle, ActionRequired=$actionRequired, ActionCompleted=$actionCompleted"

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

    Write-Timestamped "TargetCycle = $targetCycle"

    #
    # If user cycle is behind, bump it
    #
    if ($setupCycle -lt $targetCycle) {
        Write-Timestamped "SetupCycle ($setupCycle) is behind TargetCycle ($targetCycle). Updating user state."

        Set-ItemProperty -Path $HKCU -Name SetupCycle      -Value $targetCycle
        Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1
        Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0

        $actionRequired  = 1
        $actionCompleted = 0

        Write-Timestamped "User state updated: SetupCycle=$targetCycle, ActionRequired=1, ActionCompleted=0"
    }

    #
    # If no action required or already completed, exit
    #
    if ($actionRequired -ne 1 -or $actionCompleted -eq 1) {
        Write-Timestamped "No action required (ActionRequired=$actionRequired, ActionCompleted=$actionCompleted). Exiting."
        return
    }

    #
    # Execute action script
    #
    if (Test-Path $ActionScript) {
        Write-Timestamped "Executing PostInstallAction.ps1"
        Invoke-PostInstallAction
        Write-Timestamped "PostInstallAction.ps1 completed."
    }
    else {
        Write-Timestamped "Action script not found: $ActionScript"
    }

    Write-Timestamped "=== PostInstallMonitor finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    & {
        Invoke-PostInstallMonitor
    } *>&1 | Out-String -Width 1KB -Stream >> "$PSScriptRoot\..\Logs\PostInstallMonitor.log"
}