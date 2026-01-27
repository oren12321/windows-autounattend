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

        "LogonId"      = "DWord"
        "BootTime"     = "QWord"
        "Now"          = "QWord"
    }

    # -----------------------------------------------------------------
    # Component handling
    # -----------------------------------------------------------------

    # Execute each component in order
    foreach ($comp in $components) {

        # Per-component registry root
        $context.ComponentRegistry = "HKCU:\Software\PostInstall\Components\$($comp.Name)"
        $context.Now = Get-Date

        ###
        ### ADDED (Step 4): Per-component versioning
        ###

        # Read per-user SetupCycle (default 0)
        $setupCycle = 0
        if (Test-Path $context.ComponentRegistry) {
            $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue
            if ($cu -and $cu.SetupCycle) {
                $setupCycle = $cu.SetupCycle
            }
        }

        # Determine TargetCycle (component default)
        $targetCycle = $comp.TargetCycle

        # HKLM override
        $lmPath = "HKLM:\Software\PostInstall\Components\$($comp.Name)"
        if (Test-Path $lmPath) {
            $lm = Get-ItemProperty -Path $lmPath -ErrorAction SilentlyContinue
            if ($lm -and $lm.TargetCycle -and $lm.TargetCycle -gt $setupCycle) {
                $targetCycle = $lm.TargetCycle
            }
        }

        Write-Timestamped "Component '$($comp.Name)': SetupCycle=$setupCycle, TargetCycle=$targetCycle"

        # Version mismatch determines whether component *should* run
        $shouldRun = ($setupCycle -lt $targetCycle)

        # 1. Evaluate StartCondition + version check
        if ($shouldRun -and (& $comp.StartCondition $context)) {
            Write-Timestamped "StartCondition met for component."

            # 2. Run action
            Write-Timestamped "Executing component action."
            & $comp.Action $context
            Write-Timestamped "Component action completed."

            # 3. Evaluate StopCondition
            if (& $comp.StopCondition $context) {
                Write-Timestamped "StopCondition met for component."
            }

            ###
            ### ADDED (Step 4): Update per-component SetupCycle + LastRun
            ###
            if (-not (Test-Path $context.ComponentRegistry)) {
                New-Item -Path $context.ComponentRegistry -Force | Out-Null
            }

            if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
            } else {
                Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
            }
            
            if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
            }

            if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name LastRun -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value (Get-Date).Ticks -PropertyType QWord -Force | Out-Null
            } else {
                Set-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value (Get-Date).Ticks -Force
            }

        }
        else {
            Write-Timestamped "StartCondition not met or component already up-to-date."
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

                if ($type -eq "QWord" -and $value -is [DateTime]) {
                    $value = $value.Ticks
                }

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
        Write-Timestamped "No components loaded. Nothing to do."
        return
    }
    else {
        Write-Timestamped "Executing monitor with $($loadedComponents.Count) component(s)."
        Invoke-PostInstallMonitor -Component $loadedComponents
    }

    Write-Timestamped "=== Component loader finished ==="
}