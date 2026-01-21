
function Invoke-PostInstallMonitor {
    param()

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'
    $HKLM = 'HKLM:\Software\MyCompany\PostInstall'
    $ActionScript = Join-Path $PSScriptRoot 'PostInstallAction.ps1'
    . (Join-Path $PSScriptRoot 'PostInstallAction.ps1')

    $maxWaitSeconds = 300
    $waitInterval   = 5
    $elapsed        = 0

    #
    # Wait for HKCU key to appear
    #
    while (-not (Test-Path $HKCU) -and $elapsed -lt $maxWaitSeconds) {
        Start-Sleep -Seconds $waitInterval
        $elapsed += $waitInterval
    }

    if (-not (Test-Path $HKCU)) {
        return
    }

    #
    # Wait for SetupComplete = 1
    #
    $elapsed = 0
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
        return
    }

    #
    # Read state
    #
    $state          = Get-ItemProperty -Path $HKCU
    $actionRequired = $state.ActionRequired
    $actionCompleted= $state.ActionCompleted
    $setupCycle     = $state.SetupCycle

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

    #
    # If user cycle is behind, bump it
    #
    if ($setupCycle -lt $targetCycle) {
        Set-ItemProperty -Path $HKCU -Name SetupCycle      -Value $targetCycle
        Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1
        Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0

        $actionRequired  = 1
        $actionCompleted = 0
    }

    #
    # If no action required or already completed, exit
    #
    if ($actionRequired -ne 1 -or $actionCompleted -eq 1) {
        return
    }

    #
    # Execute action script
    #
    if (Test-Path $ActionScript) {
        Invoke-PostInstallAction
    }
}

#
# Auto-run only when executed directly, not when dot-sourced or imported
#
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-PostInstallMonitor
}