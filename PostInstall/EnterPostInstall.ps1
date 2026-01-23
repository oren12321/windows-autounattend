. (Join-Path $PSScriptRoot '..\Utils\Output.ps1')

function Invoke-EnterPostInstall {
    param()

    Write-Timestamped "=== EnterPostInstall started ==="

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'

    #
    # Ensure HKCU key exists
    #
    if (-not (Test-Path $HKCU)) {
        Write-Timestamped "Creating HKCU key: $HKCU"
        New-Item -Path $HKCU -Force | Out-Null
    }
    else {
        Write-Timestamped "HKCU key already exists: $HKCU"
    }

    #
    # Check if state already initialized
    #
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    if ($state) {
        Write-Timestamped "State already initialized. SetupComplete=$($state.SetupComplete), SetupCycle=$($state.SetupCycle)"
        Write-Timestamped "=== EnterPostInstall finished (no changes) ==="
        return
    }

    #
    # Initialize per-user state
    #
    Write-Timestamped "Initializing per-user post-install state."

    New-ItemProperty -Path $HKCU -Name SetupComplete   -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name SetupCycle      -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0 -PropertyType DWord -Force | Out-Null

    Write-Timestamped "Initialized: SetupComplete=1, SetupCycle=1, ActionRequired=1, ActionCompleted=0"
    Write-Timestamped "=== EnterPostInstall finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-EnterPostInstall
}
