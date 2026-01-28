. (Join-Path $PSScriptRoot '..\Utils\Logging.ps1')

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
        $Components  # Array of components
    )

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

        Now             = $null
        LastRun         = $null
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

    foreach ($comp in $Components) {

        Write-Timestamped "Starting evaluation of component '$($comp.Name)'"

        $context.ComponentRegistry = "HKCU:\Software\PostInstall\Components\$($comp.Name)"
        $context.Now = Get-Date

        # Assumption: given component via loader is valid - so let's create its registry if not exist
        try {
            if (-not (Test-Path $context.ComponentRegistry)) {
                Write-Timestamped "Creating registry key: $($context.ComponentRegistry)"
                New-Item -Path $context.ComponentRegistry -Force | Out-Null
            }
        }
        catch {
            Write-Timestamped "ERROR: Failed to create registry key for component '$($comp.Name)': $_"
        }

        # Load LastRun to context
        if (Test-Path $context.ComponentRegistry) {
            $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue
            if ($cu -and $cu.LastRun) {
                $context.LastRun = [DateTime]::FromFileTimeUtc($cu.LastRun)
            }
        }

        # Read per-user SetupCycle (default 0)
        $setupCycle = 0
        if (Test-Path $context.ComponentRegistry) {
            $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue
            if ($cu -and $cu.SetupCycle) {
                $setupCycle = $cu.SetupCycle
            }
        }

        # Determine user's TargetCycle
        $targetCycle = 0
        if (Test-Path $context.ComponentRegistry) {
            $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue
            if ($cu) {
                if ($cu.TargetCycle) {
                    $targetCycle = $cu.TargetCycle
                }
                else {
                    try {
                        Write-Timestamped "Ensuring TargetCycle=$targetCycle - first initialization"
                        if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -ErrorAction SilentlyContinue)) {
                            New-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                        } else {
                            Set-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -Force
                        }
                    }
                    catch {
                        Write-Timestamped "ERROR: Failed to ensure first initialization of target cycle for component '$($comp.Name)': $_"
                    }
                }
            }
        }

        # HKLM override
        $lmPath = "HKLM:\Software\PostInstall\Components\$($comp.Name)"
        if (Test-Path $lmPath) {
            $lm = Get-ItemProperty -Path $lmPath -ErrorAction SilentlyContinue
            if ($lm -and $lm.TargetCycle -and $lm.TargetCycle -gt $setupCycle) {
                $targetCycle = $lm.TargetCycle
                
                try {
                    Write-Timestamped "Ensuring TargetCycle=$targetCycle - HKLM override"
                    if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -ErrorAction SilentlyContinue)) {
                        New-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                    } else {
                        Set-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -Force
                    }
                }
                catch {
                    Write-Timestamped "ERROR: Failed to ensure overrided target cycle for component '$($comp.Name)': $_"
                }
            }
        }

        Write-Timestamped "Component '$($comp.Name)': SetupCycle=$setupCycle, TargetCycle=$targetCycle"

        # 1. Check version
        $outOfDateVersion = ($setupCycle -lt $targetCycle)
        if (-not $outOfDateVersion) {
            Write-Timestamped "Skipping component '$($comp.Name)'. Already up do date."
            continue
        }
        
        try {
            Write-Timestamped "Executing component reset."
            & $comp.Reset $context
            Write-Timestamped "Component reset completed."
        }
        catch {
            Write-Timestamped "WARNING Unhandled exception in Reset of component '$($comp.Name)': $_"
        }

        # 2. Evaluate StartCondition
        try {
            $isStartCondition = (& $comp.StartCondition $context)
        }
        catch {
            Write-Timestamped "ERROR: Unhandled exception in StartCondition of component '$($comp.Name)': $_"
            $isStartCondition = $false
        }
        if (-not $isStartCondition) {
            Write-Timestamped "Skipping component '$($comp.Name)'. StartCondition not met"
            continue
        }
        
        # 3. Evaluate StopCondition
        try {
            $isStopCondition = (& $comp.StopCondition $context)
        }
        catch {
            Write-Timestamped "ERROR: Unhandled exception in StopCondition of component '$($comp.Name)': $_"
            $isStopCondition = $false
        }
        if ($isStopCondition) {
            Write-Timestamped "Cycle completed for component '$($comp.Name)' in later monitor invocation"
            try {
                Write-Timestamped "Updating SetupCycle to $targetCycle"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
                }

                $ticks = (Get-Date).Ticks
                Write-Timestamped "Updating LastRun=$ticks"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name LastRun -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -PropertyType QWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -Force
                }
            }
            catch {
                Write-Timestamped "ERROR: Failed to update registry versions for component '$($comp.Name)': $_"
            }
            
            Write-Timestamped "Skipping component '$($comp.Name)'. StopCondition is met"
            continue
        }
        
        # 4. Run Action
        try {
            Write-Timestamped "Executing component action."
            & $comp.Action $context
            Write-Timestamped "Component action completed."
        }
        catch {
            Write-Timestamped "WARNING Unhandled exception in Action of component '$($comp.Name)': $_"
        }
        
        # 5. Save context to component registry
        try {
            foreach ($entry in $PersistenceMap.GetEnumerator()) {
                $name = $entry.Key
                $type = $entry.Value

                if ($context.PSObject.Properties[$name]) {
                    $value = $context.$name

                    if ($type -eq "QWord" -and $value -is [DateTime]) {
                        $value = $value.Ticks
                    }

                    if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name $name -ErrorAction SilentlyContinue)) {
                        Write-Timestamped "Writing registry value: $name = $value"
                        New-ItemProperty -Path $context.ComponentRegistry -Name $name -Value $value -PropertyType $type -Force | Out-Null
                    }
                    else {
                        Write-Timestamped "Updating registry value: $name = $value"
                        Set-ItemProperty -Path $context.ComponentRegistry -Name $name -Value $value -Force
                    }
                }
            }
        }
        catch {
            Write-Timestamped "ERROR: Failed to persist context for component '$($comp.Name)': $_"
        }
        
        # 6. Update per-component SetupCycle + LastRun
        try {
            $isStopCondition = (& $comp.StopCondition $context)
        }
        catch {
            Write-Timestamped "ERROR: Unhandled exception in StopCondition re-evaluation of component '$($comp.Name)': $_"
            $isStopCondition = $false
        }
        if ($isStopCondition) {
            Write-Timestamped "Cycle completed for component '$($comp.Name)'"
            try {
                Write-Timestamped "Updating SetupCycle to $targetCycle"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
                }

                $ticks = (Get-Date).Ticks
                Write-Timestamped "Updating LastRun=$ticks"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name LastRun -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -PropertyType QWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -Force
                }
            }
            catch {
                Write-Timestamped "ERROR: Failed to update registry versions for component '$($comp.Name)': $_"
            }
        } 
    }
}