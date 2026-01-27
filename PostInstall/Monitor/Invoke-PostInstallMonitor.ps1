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

    foreach ($comp in $Components) {

        $context.ComponentRegistry = "HKCU:\Software\PostInstall\Components\$($comp.Name)"
        $context.Now = Get-Date

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

            # Update per-component SetupCycle + LastRun
            try {
                if (-not (Test-Path $context.ComponentRegistry)) {
                    Write-Timestamped "Creating registry key: $($context.ComponentRegistry)"
                    New-Item -Path $context.ComponentRegistry -Force | Out-Null
                }

                Write-Timestamped "Updating SetupCycle to $targetCycle"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
                } else {
                    Set-ItemProperty -Path $context.ComponentRegistry -Name SetupCycle -Value $targetCycle -Force
                }

                Write-Timestamped "Ensuring TargetCycle=$targetCycle"
                if (-not (Get-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path $context.ComponentRegistry -Name TargetCycle -Value $targetCycle -PropertyType DWord -Force | Out-Null
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
                Write-Timestamped "ERROR: Failed to update registry for component '$($comp.Name)': $_"
            }

        }
        else {
            Write-Timestamped "StartCondition not met or component already up-to-date."
        }

        # Save context to component registry
        $regPath = $context.ComponentRegistry

        try {
            if (-not (Test-Path $regPath)) {
                Write-Timestamped "Creating registry key: $regPath"
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
                        Write-Timestamped "Writing registry value: $name = $value"
                        New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType $type -Force | Out-Null
                    }
                    else {
                        Write-Timestamped "Updating registry value: $name = $value"
                        Set-ItemProperty -Path $regPath -Name $name -Value $value -Force
                    }
                }
            }
        }
        catch {
            Write-Timestamped "ERROR: Failed to persist context for component '$($comp.Name)': $_"
        }
    }
}