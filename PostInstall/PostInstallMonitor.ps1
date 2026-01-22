. (Join-Path $PSScriptRoot '..\Utils\Output.ps1')
. (Join-Path $PSScriptRoot 'Utils\PostInstallComponent.ps1')

function Invoke-PostInstallMonitor {
    param(
        $Component
    )

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
    # Build default component if none injected
    #
    if (-not $Component) {
        $Component = New-PostInstallComponent `
            -StartCondition {
                param($s)
                # Default: run when ActionRequired=1 and not completed
                $s.ActionRequired -eq 1 -and $s.ActionCompleted -ne 1
            } `
            -Action {
                Invoke-PostInstallAction
            } `
            -StopCondition {
                param($s)
                # Default: stop when ActionCompleted=1
                $s.ActionCompleted -eq 1
            }
    }

    #
    # 1. Evaluate StartCondition: if true, mark ActionRequired=1, ActionCompleted=0
    #
    $state = Get-ItemProperty -Path $HKCU
    if (& $Component.StartCondition $state) {
        Write-Timestamped "StartCondition met. Marking ActionRequired=1, ActionCompleted=0"
        Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1
        Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0
        $state = Get-ItemProperty -Path $HKCU
    }

    #
    # 2. Run action whenever ActionRequired=1 and not completed
    #
    if ($state.ActionRequired -eq 1 -and $state.ActionCompleted -ne 1) {
        if ($Component.Action) {
            Write-Timestamped "Executing component action."
            & $Component.Action $state
            Write-Timestamped "Component action completed."
        }
        elseif (Test-Path $ActionScript) {
            Write-Timestamped "Executing PostInstallAction.ps1"
            Invoke-PostInstallAction
            Write-Timestamped "PostInstallAction.ps1 completed."
        }
        else {
            Write-Timestamped "Action script not found: $ActionScript"
        }

        $state = Get-ItemProperty -Path $HKCU
    }
    else {
        Write-Timestamped "No action required (ActionRequired=$($state.ActionRequired), ActionCompleted=$($state.ActionCompleted))."
    }

    #
    # 3. Evaluate StopCondition: if true, mark ActionCompleted=1, ActionRequired=0
    #
    if (& $Component.StopCondition $state) {
        Write-Timestamped "StopCondition met. Marking ActionCompleted=1, ActionRequired=0"
        Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 1
        Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 0
    }

    Write-Timestamped "=== PostInstallMonitor finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    & {
        Invoke-PostInstallMonitor
    } *>&1 | Out-String -Width 1KB -Stream >> "$PSScriptRoot\..\Logs\PostInstallMonitor.log"
}