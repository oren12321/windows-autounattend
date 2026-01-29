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

        Write-Timestamped (Format-Line -Level "Info" -Message "Starting evaluation of '$($comp.Name)'")

        $context.ComponentRegistry = "HKCU:\Software\PostInstall\Components\$($comp.Name)"
        $context.Now = Get-Date

        Write-Timestamped (Format-Line -Level "Info" -Message "Current context of '$($comp.Name)': $context")

        # Assumption: given component via loader is valid - so let's create its registry if not exist
        if (-not (Test-Path $context.ComponentRegistry)) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Creating $($context.ComponentRegistry)")
            try {
                New-Item -Path $context.ComponentRegistry -Force | Out-Null
            }
            catch {
                Write-Timestamped (Format-Line -Level "Error" -Message "Failed to create $($context.ComponentRegistry): $_")
                Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)' evaluation")
                continue
            }
        }
        
        # Load LastRun to context
        $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue
        if ($cu -and $cu.LastRun) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Loading LastRun to '$($comp.Name)' context")
            $context.LastRun = [DateTime]::FromFileTimeUtc($cu.LastRun)
        }

        $cu = Get-ItemProperty -Path $context.ComponentRegistry -ErrorAction SilentlyContinue

        # Read per-user SetupCycle (default 0)
        $setupCycle = 0
        if ($cu -and $cu.SetupCycle) {
            $setupCycle = $cu.SetupCycle
        }

        # Read per-user TargetCycle (default 0)
        $targetCycle = 0
        if ($cu -and $cu.TargetCycle) {
            $targetCycle = $cu.TargetCycle
        }
        else {
            Write-Timestamped (Format-Line -Level "Info" -Message "Creating TargetCycle=$targetCycle in $($context.ComponentRegistry)")
            try {
                New-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
            }
            catch {
                Write-Timestamped (Format-Line -Level "Error" -Message "Failed to create TargetCycle=$targetCycle in $($context.ComponentRegistry): $_")
                Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)' evaluation")
                continue
            }
        }

        # HKLM override
        $lmPath = "HKLM:\Software\PostInstall\Components\$($comp.Name)"
        if (Test-Path $lmPath) {
            $lm = Get-ItemProperty -Path $lmPath -ErrorAction SilentlyContinue
            if ($lm -and $lm.TargetCycle -and $lm.TargetCycle -gt $setupCycle) {
                $targetCycle = $lm.TargetCycle
                
                try {
                    Write-Timestamped (Format-Line -Level "Info" -Message "Overriding HKLM TargetCycle=$targetCycle in $($context.ComponentRegistry)")
                    Set-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -Force
                }
                catch {
                    Write-Timestamped (Format-Line -Level "Warning" -Message "Failed to override HKLM TargetCycle=$targetCycle in $($context.ComponentRegistry): $_")
                }
            }
        }

        Write-Timestamped (Format-Line -Level "Info" -Message "Current '$($comp.Name)' versions: SetupCycle=$setupCycle, TargetCycle=$targetCycle")

        # Check version
        $outOfDateVersion = ($setupCycle -lt $targetCycle)
        if (-not $outOfDateVersion) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)' evaluation. Already up do date.")
            continue
        }
        
        # Run Reset if exist
        if ($comp.Reset) {
            try {
                Write-Timestamped (Format-Line -Level "Info" -Message "Executing '$($comp.Name)' Reset.")
                & $comp.Reset $context
                Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' Reset completed.")
            }
            catch {
                Write-Timestamped (Format-Line -Level "Warning" -Message "Unhandled exception in Reset of '$($comp.Name)': $_")
            }
        }

        # Evaluate StartCondition
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Evaluating '$($comp.Name)' StartCondition.")
            $isStartCondition = (& $comp.StartCondition $context)
            Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' StartCondition evaluation completed.")
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Defaulting '$($comp.Name)' StartCondition to false. Unhandled exception: $_")
            $isStartCondition = $false
        }
        if (-not $isStartCondition) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)'. StartCondition not met")
            continue
        }
        
        # Evaluate StopCondition
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Evaluating '$($comp.Name)' pre-Action StopCondition.")
            $isStopCondition = (& $comp.StopCondition $context)
            Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' pre-Action StopCondition evaluation completed.")
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Defaulting '$($comp.Name)' StopCondition to false. Unhandled exception: $_")
            $isStartCondition = $false
        }
        if ($isStopCondition) {
            # Run Cleanup if exist
            if ($comp.Cleanup) {
                try {
                    Write-Timestamped (Format-Line -Level "Info" -Message "Executing '$($comp.Name)' Cleanup.")
                    & $comp.Cleanup $context
                    Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' Cleanup completed.")
                }
                catch {
                    Write-Timestamped (Format-Line -Level "Warning" -Message "Unhandled exception in Cleanup of '$($comp.Name)': $_")
                }
            }
            
            Write-Timestamped (Format-Line -Level "Info" -Message "Cycle completed for '$($comp.Name)' before Action run or in later monitor invocation")
            try {
                Write-Timestamped (Format-Line -Level "Info" -Message "Ensuring SetupCycle=$targetCycle in $($context.ComponentRegistry)")
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
                }
            }
            catch {
                Write-Timestamped (Format-Line -Level "Error" -Message "Failed to ensure SetupCycle=$targetCycle in $($context.ComponentRegistry): $_")
                Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)' evaluation")
                continue
            }

            try {
                $ticks = (Get-Date).Ticks
                Write-Timestamped (Format-Line -Level "Info" -Message "Ensuring LastRun=$ticks in $($context.ComponentRegistry)")
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name LastRun -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -PropertyType QWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -Force
                }
            }
            catch {
                Write-Timestamped (Format-Line -Level "Warning" -Message "Failed to ensure LastRun=$ticks in $($context.ComponentRegistry): $_")
            }
            
            Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)'. StopCondition is met")
            continue
        }
        
        # Run Action
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Executing '$($comp.Name)' Action.")
            & $comp.Action $context
            Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' Action completed.")
        }
        catch {
            Write-Timestamped (Format-Line -Level "Warning" -Message "Unhandled exception in Action of '$($comp.Name)': $_")
        }
        
        # Save context to component registry
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Persisting context in $($context.ComponentRegistry)")
            foreach ($entry in $PersistenceMap.GetEnumerator()) {
                $name = $entry.Key
                $type = $entry.Value

                if ($context.PSObject.Properties[$name]) {
                    $value = $context.$name

                    if ($type -eq "QWord" -and $value -is [DateTime]) {
                        $value = $value.Ticks
                    }

                    if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name $name -ErrorAction SilentlyContinue)) {
                        New-ItemProperty -Path $context.ComponentRegistry -Name $name -Value $value -PropertyType $type -Force | Out-Null
                    }
                    else {
                        Set-ItemProperty -Path $context.ComponentRegistry -Name $name -Value $value -Force
                    }
                }
            }
        }
        catch {
            Write-Timestamped (Format-Line -Level "Warning" -Message "Failed to persist context in $($context.ComponentRegistry): $_")
        }
        
        # Re-evaluate stop condition
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Evaluating '$($comp.Name)' post-Action StopCondition.")
            $isStopCondition = (& $comp.StopCondition $context)
            Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' post-Action StopCondition evaluation completed.")
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Defaulting '$($comp.Name)' StopCondition to false. Unhandled exception: $_")
            $isStartCondition = $false
        }
        if ($isStopCondition) {
            # Run Cleanup if exist
            if ($comp.Cleanup) {
                try {
                    Write-Timestamped (Format-Line -Level "Info" -Message "Executing '$($comp.Name)' Cleanup.")
                    & $comp.Cleanup $context
                    Write-Timestamped (Format-Line -Level "Info" -Message "'$($comp.Name)' Cleanup completed.")
                }
                catch {
                    Write-Timestamped (Format-Line -Level "Warning" -Message "Unhandled exception in Cleanup of '$($comp.Name)': $_")
                }
            }
            
            Write-Timestamped (Format-Line -Level "Info" -Message "Cycle completed for '$($comp.Name)' before Action run or in later monitor invocation")
            try {
                Write-Timestamped (Format-Line -Level "Info" -Message "Ensuring SetupCycle=$targetCycle in $($context.ComponentRegistry)")
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
                }
            }
            catch {
                Write-Timestamped (Format-Line -Level "Error" -Message "Failed to ensure SetupCycle=$targetCycle in $($context.ComponentRegistry): $_")
                Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)' evaluation")
                continue
            }

            try {
                $ticks = (Get-Date).Ticks
                Write-Timestamped (Format-Line -Level "Info" -Message "Ensuring LastRun=$ticks in $($context.ComponentRegistry)")
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name LastRun -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -PropertyType QWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name LastRun -Value $ticks -Force
                }
            }
            catch {
                Write-Timestamped (Format-Line -Level "Warning" -Message "Failed to ensure LastRun=$ticks in $($context.ComponentRegistry): $_")
            }
            
            Write-Timestamped (Format-Line -Level "Info" -Message "Skipping '$($comp.Name)'. StopCondition is met")
            continue
        }
    }
}