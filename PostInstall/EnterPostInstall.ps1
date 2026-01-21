
function Invoke-EnterPostInstall {
    param()

    $HKCU = 'HKCU:\Software\MyCompany\PostInstall'

    if (-not (Test-Path $HKCU)) {
        New-Item -Path $HKCU -Force | Out-Null
    }

    # Initialize per-user state only if not already initialized
    $state = Get-ItemProperty -Path $HKCU -ErrorAction SilentlyContinue

    if (-not $state) {
        New-ItemProperty -Path $HKCU -Name SetupComplete   -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $HKCU -Name SetupCycle      -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $HKCU -Name ActionRequired  -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $HKCU -Name ActionCompleted -Value 0 -PropertyType DWord -Force | Out-Null
    }
}

# Auto-run only when executed directly, not when dot-sourced
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-EnterPostInstall
}