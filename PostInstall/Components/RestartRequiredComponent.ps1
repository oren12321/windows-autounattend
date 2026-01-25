# RestartRequiredComponent.ps1
# Requires: New-PostInstallComponent

. "$PSScriptRoot\..\Utils\PostInstallComponent.ps1"

$Component = New-PostInstallComponent `
    -Name "RestartRequired" `
    -StartCondition {
        param($context)

        $asPath = 'HKCU:\Software\Microsoft\Active Setup\Installed Components\MySetup'

        if (-not (Test-Path $asPath)) {
            return $false
        }

        $state = Get-ItemProperty -Path $asPath -ErrorAction SilentlyContinue
        if (-not $state) {
            return $false
        }

        # Active Setup completed for this user
        return ($state.SetupComplete -eq 1)
    } `
    -Action {
        param($context)

        $toastScript = 'C:\MySetup\Scripts\Toast.ps1'

        & $context.Log "Showing restart-required toast for user '$($context.UserName)'"

        if (Test-Path $toastScript) {
            Start-Process powershell.exe `
                -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$toastScript`"" `
                -WindowStyle Hidden
        }
        else {
            & $context.Log "Toast script not found: $toastScript"
        }
    } `
    -StopCondition {
        param($context)

        # The monitor already computed the user's logon ID at startup.
        # If the current logon ID differs, the user logged out or restarted.

        $current = $context.LogonId
        $now     = Get-CurrentLogonId   # Provided by the monitor's environment

        if ($now -ne $current) {
            & $context.Log "User session changed (LogonId $current -> $now). Component complete."
            return $true
        }

        return $false
    }