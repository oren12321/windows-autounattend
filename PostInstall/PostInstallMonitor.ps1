. (Join-Path $PSScriptRoot '..\Utils\Output.ps1')
. (Join-Path $PSScriptRoot 'Utils\PostInstallComponent.ps1')

function Get-CurrentWindowsIdentityName {
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Get-LogonSessions {
    Get-CimInstance Win32_LoggedOnUser
}

function Get-CurrentLogonId {
    $currentUser = Get-CurrentWindowsIdentityName
    
    # Get all associations
    $assoc = Get-LogonSessions
    
    # Convert them into usable objects
    $mapped = foreach ($a in $assoc) {
        $acc = [string]$a.Antecedent
        $ses = [string]$a.Dependent
        
        $isAccMatch = $acc -match 'Name[ ]*=[ ]*"([^"]+)"[ ]*,[ ]*Domain[ ]*=[ ]*"([^"]+)"'
        if ($isAccMatch) {
            $user = "$($Matches[2])\$($Matches[1])"
        }
        
        $isSesMatch = $ses -match 'LogonId[ ]*=[ ]*"([^"]+)"'
        if ($isSesMatch) {
            $logonId = $Matches[1]
        }

        if ($isAccMatch -and $isSesMatch) {

            [pscustomobject]@{
                User    = $user
                LogonId = $logonId
            }
        }
    }

    # Find the current user
    $mapped |
        Where-Object { $_.User -eq $currentUser } |
        Select-Object -First 1 |
        ForEach-Object { $_.LogonId }
}


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

    # -----------------------------------------------------------------
    # Build context (public API for components)
    # -----------------------------------------------------------------
    $context = [pscustomobject]@{
        UserName        = $env:USERNAME
        UserProfile     = $env:USERPROFILE
        LocalAppData    = $env:LOCALAPPDATA
        ProgramData     = $env:ProgramData

        LogonId         = Get-CurrentLogonId
        BootTime        = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

        Log             = { param($msg) Write-Timestamped $msg }

        ComponentRegistry = $null

        Now             = Get-Date
    }
    $PersistenceMap = @{
        "UserName"     = "String"
        "UserProfile"  = "String"
        "LocalAppData" = "String"
        "ProgramData"  = "String"

        "LogonId"      = "DWord"   # numeric session ID
        "BootTime"     = "QWord"   # DateTime.Ticks
        "Now"          = "QWord"   # DateTime.Ticks
    }

    # -----------------------------------------------------------------
    # Component handling
    # -----------------------------------------------------------------

    # Normalize to array
    $components = @()
    if ($Component -is [array]) {
        $components = $Component
    }
    elseif ($Component) {
        $components = @($Component)
    }

    # Default component (keeps old HKCU behavior, but via context)
    if ($components.Count -eq 0) {
        Write-Timestamped "No injected components. Using default component."

        $default = New-PostInstallComponent `
            -StartCondition {
                param($context)
                $hkcu = 'HKCU:\Software\MyCompany\PostInstall'
                if (-not (Test-Path $hkcu)) { return $false }
                $s = Get-ItemProperty -Path $hkcu
                $s.ActionRequired -eq 1 -and $s.ActionCompleted -ne 1
            } `
            -Action {
                param($context)
                Invoke-PostInstallAction
            } `
            -StopCondition {
                param($context)
                $hkcu = 'HKCU:\Software\MyCompany\PostInstall'
                if (-not (Test-Path $hkcu)) { return $false }
                $s = Get-ItemProperty -Path $hkcu
                $s.ActionCompleted -eq 1
            }

        $components = @($default)
    }

    #
    # Execute each component in order
    #
    foreach ($comp in $components) {

        # Per-component registry root
        $context.ComponentRegistry = "HKCU:\Software\MyCompany\PostInstall\Components\$($comp.Name)"
        $context.Now = Get-Date

        # 1. Evaluate StartCondition
        if (& $comp.StartCondition $context) {
            Write-Timestamped "StartCondition met for component."

            # 2. Run action
            if ($comp.Action) {
                Write-Timestamped "Executing component action."
                & $comp.Action $context
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

            # 3. Evaluate StopCondition
            if (& $comp.StopCondition $context) {
                Write-Timestamped "StopCondition met for component."
                # For now, we just log; components own their own state.
                # You can later add global bookkeeping here if needed.
            }
        }
        else {
            Write-Timestamped "StartCondition not met for component."
        }
        
        # Save context to component registry
        $regPath = $context.ComponentRegistry

        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        foreach ($entry in $PersistenceMap.GetEnumerator()) {
            $name = $entry.Key
            $type = $entry.Value

            if ($context.PSObject.Properties[$name]) {
                $value = $context.$name

                # Convert DateTime to ticks for QWORD storage
                if ($type -eq "QWord" -and $value -is [DateTime]) {
                    $value = $value.Ticks
                }

                # Create or update explicitly typed registry value
                if (-not (Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType $type -Force | Out-Null
                }
                else {
                    Set-ItemProperty -Path $regPath -Name $name -Value $value -Force
                }
            }
        }
    }

    Write-Timestamped "=== PostInstallMonitor finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -ne '.') {

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