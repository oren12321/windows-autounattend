
function Invoke-PostInstallAction {
    param()

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    if (-not $state) { return }

    if ($state.ActionRequired -ne 1 -or $state.ActionCompleted -eq 1) { return }

    $toast = Join-Path $PSScriptRoot 'Toast.ps1'

    if (Test-Path $toast) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$toast`"" -WindowStyle Hidden
    }

    Set-ItemProperty -Path $HKCU -Name ActionCompleted -Value 1
    Set-ItemProperty -Path $HKCU -Name ActionRequired  -Value 0
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-PostInstallAction
}