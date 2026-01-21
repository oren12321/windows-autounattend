$logFile = Join-Path $PSScriptRoot 'EnterPostInstall.log'

# Logging helper
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Out-File $logFile -Append
}

function Invoke-EnterPostInstall {
    param()

    Write-Log "=== EnterPostInstall started ==="

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'

    #
    # Ensure HKCU key exists
    #
    if (-not (Test-Path $HKCU)) {
        Write-Log "Creating HKCU key: $HKCU"
        New-Item -Path $HKCU -Force | Out-Null
    }
    else {
        Write-Log "HKCU key already exists: $HKCU"
    }

    #
    # Check if state already initialized
    #
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    if ($state) {
        Write-Log "State already initialized. SetupComplete=$($state.SetupComplete), SetupCycle=$($state.SetupCycle)"
        Write-Log "=== EnterPostInstall finished (no changes) ==="
        return
    }

    #
    # Initialize per-user state
    #
    Write-Log "Initializing per-user post-install state."

    New-ItemProperty -Path $HKCU -Name SetupComplete   -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name SetupCycle      -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0 -PropertyType DWord -Force | Out-Null

    Write-Log "Initialized: SetupComplete=1, SetupCycle=1, ActionRequired=1, ActionCompleted=0"
    Write-Log "=== EnterPostInstall finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-EnterPostInstall
}
