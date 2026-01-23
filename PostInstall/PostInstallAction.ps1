. (Join-Path $PSScriptRoot '..\Utils\Output.ps1')

function Invoke-PostInstallAction {
    param()

    Write-Timestamped "=== PostInstallAction started ==="

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    #
    # Validate state exists
    #
    if (-not $state) {
        Write-Timestamped "State not found at $HKCU. Exiting."
        Write-Timestamped "=== PostInstallAction finished ==="
        return
    }

    #
    # Check if action is required
    #
    if ($state.ActionRequired -ne 1 -or $state.ActionCompleted -eq 1) {
        Write-Timestamped "Action not required (ActionRequired=$($state.ActionRequired), ActionCompleted=$($state.ActionCompleted)). Exiting."
        Write-Timestamped "=== PostInstallAction finished ==="
        return
    }

    Write-Timestamped "Action required. Proceeding."

    #
    # Optional toast notification
    #
    $toast = Join-Path $PSScriptRoot 'Toast.ps1'

    if (Test-Path $toast) {
        Write-Timestamped "Launching toast script: $toast"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$toast`"" -WindowStyle Hidden
    }
    else {
        Write-Timestamped "Toast script not found: $toast"
    }

    #
    # Update registry flags
    #
    Write-Timestamped "Updating registry flags: ActionCompleted=1, ActionRequired=0"

    Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 1
    Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 0

    Write-Timestamped "Post-install action completed successfully."
    Write-Timestamped "=== PostInstallAction finished ==="
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-PostInstallAction
}