$logFile = Join-Path $PSScriptRoot 'PostInstallAction.log'

# Logging helper
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Out-File $logFile -Append
}

function Invoke-PostInstallAction {
    param()

    Write-Log "=== PostInstallAction started ==="

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    #
    # Validate state exists
    #
    if (-not $state) {
        Write-Log "State not found at $HKCU. Exiting."
        Write-Log "=== PostInstallAction finished ==="
        return
    }

    #
    # Check if action is required
    #
    if ($state.ActionRequired -ne 1 -or $state.ActionCompleted -eq 1) {
        Write-Log "Action not required (ActionRequired=$($state.ActionRequired), ActionCompleted=$($state.ActionCompleted)). Exiting."
        Write-Log "=== PostInstallAction finished ==="
        return
    }

    Write-Log "Action required. Proceeding."

    #
    # Optional toast notification
    #
    $toast = Join-Path $PSScriptRoot 'Toast.ps1'

    if (Test-Path $toast) {
        Write-Log "Launching toast script: $toast"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$toast`"" -WindowStyle Hidden
    }
    else {
        Write-Log "Toast script not found: $toast"
    }

    #
    # Update registry flags
    #
    Write-Log "Updating registry flags: ActionCompleted=1, ActionRequired=0"

    Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 1
    Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 0

    Write-Log "Post-install action completed successfully."
    Write-Log "=== PostInstallAction finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-PostInstallAction
}