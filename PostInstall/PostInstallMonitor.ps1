param(
    [switch]$InTestContext
)

. (Join-Path $PSScriptRoot '..\Utils\Output.ps1')
. (Join-Path $PSScriptRoot 'Utils\PostInstallComponent.ps1')

function Invoke-PostInstallMonitor {
    param(
        $Component  # Can be a single component OR an array of components
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

    # =====================================================================
    # NEW COMPONENT HANDLING BLOCK (replaces your old "Build default component" block)
    # =====================================================================

    #
    # Normalize to array
    #
    $components = @()
    if ($Component -is [array]) {
        $components = $Component
    }
    elseif ($Component) {
        $components = @($Component)
    }

    #
    # If no components were injected, build the default one
    #
    if ($components.Count -eq 0) {
        Write-Timestamped "No injected components. Using default component."

        $default = New-PostInstallComponent `
            -StartCondition {
                param($s)
                $s.ActionRequired -eq 1 -and $s.ActionCompleted -ne 1
            } `
            -Action {
                Invoke-PostInstallAction
            } `
            -StopCondition {
                param($s)
                $s.ActionCompleted -eq 1
            }

        $components = @($default)
    }

    # =====================================================================
    # END OF NEW COMPONENT HANDLING BLOCK
    # =====================================================================

    #
    # Execute each component in order
    #
    foreach ($comp in $components) {

        # 1. Evaluate StartCondition
        $state = Get-ItemProperty -Path $HKCU
        if (& $comp.StartCondition $state) {
            Write-Timestamped "StartCondition met for component. Marking ActionRequired=1, ActionCompleted=0"
            Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1
            Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0
            $state = Get-ItemProperty -Path $HKCU
        }

        # 2. Run action if required
        if ($state.ActionRequired -eq 1 -and $state.ActionCompleted -ne 1) {
            if ($comp.Action) {
                Write-Timestamped "Executing component action."
                & $comp.Action $state
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

        # 3. Evaluate StopCondition
        if (& $comp.StopCondition $state) {
            Write-Timestamped "StopCondition met for component. Marking ActionCompleted=1, ActionRequired=0"
            Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 1
            Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 0
        }
    }

    Write-Timestamped "=== PostInstallMonitor finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name -or $InTestContext) {

    Write-Timestamped "=== Component loader started ==="

    $componentsDir = Join-Path $PSScriptRoot "Components"
    $singleComponentPath = Join-Path $PSScriptRoot "Component.ps1"

    $loadedComponents = @()

    try {
        if (Test-Path $componentsDir) {
            Write-Timestamped "Loading components from folder: $componentsDir"

            $files = Get-ChildItem -Path $componentsDir -Filter *.ps1 | Sort-Object Name

            foreach ($file in $files) {
                Write-Timestamped "Loading component file: $($file.Name)"

                try {
                    . $file.FullName

                    if (-not $Component) {
                        Write-Timestamped "ERROR: Component file '$($file.Name)' did not define a `$Component variable. Skipping."
                        continue
                    }

                    # Validate structure
                    if (-not ($Component.StartCondition -is [scriptblock] -and
                              $Component.Action         -is [scriptblock] -and
                              $Component.StopCondition  -is [scriptblock])) {

                        Write-Timestamped "ERROR: Component '$($file.Name)' is missing required scriptblocks. Skipping."
                        continue
                    }

                    $loadedComponents += $Component
                    Write-Timestamped "Component '$($file.Name)' loaded successfully."
                }
                catch {
                    Write-Timestamped "ERROR: Failed to load component '$($file.Name)': $_"
                }

                Remove-Variable Component -ErrorAction SilentlyContinue
            }
        }
        elseif (Test-Path $singleComponentPath) {
            Write-Timestamped "Loading single component file: $singleComponentPath"

            try {
                . $singleComponentPath

                if (-not $Component) {
                    Write-Timestamped "ERROR: Component.ps1 did not define a `$Component variable."
                }
                elseif (-not ($Component.StartCondition -is [scriptblock] -and
                              $Component.Action         -is [scriptblock] -and
                              $Component.StopCondition  -is [scriptblock])) {

                    Write-Timestamped "ERROR: Component.ps1 is missing required scriptblocks."
                }
                else {
                    $loadedComponents += $Component
                    Write-Timestamped "Component.ps1 loaded successfully."
                }
            }
            catch {
                Write-Timestamped "ERROR: Failed to load Component.ps1: $_"
            }
        }
        else {
            Write-Timestamped "No component files found. Using default component."
        }
    }
    catch {
        Write-Timestamped "ERROR: Unexpected failure during component loading: $_"
    }

    # Fallback to default component if none loaded
    if ($loadedComponents.Count -eq 0) {
        Write-Timestamped "WARNING: No valid components loaded. Falling back to default component."

        Invoke-PostInstallMonitor
    }
    else {
        Write-Timestamped "Executing monitor with $($loadedComponents.Count) component(s)."

        Invoke-PostInstallMonitor -Component $loadedComponents
    }

    Write-Timestamped "=== Component loader finished ==="
}