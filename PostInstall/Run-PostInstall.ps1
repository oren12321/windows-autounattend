param(
    [string] $ComponentsDirectory = (Join-Path $PSScriptRoot "Components")
)

. (Join-Path $PSScriptRoot "Utils\Logging.ps1")

Write-Timestamped "=== Component loader started ==="

# Load the loader function and monitor function
. (Join-Path $PSScriptRoot "Monitor\Load-PostInstallComponents.ps1")
. (Join-Path $PSScriptRoot "Monitor\Invoke-PostInstallMonitor.ps1")

# Load components
$loadedComponents = Load-PostInstallComponents -ComponentsDirectory $ComponentsDirectory

if ($loadedComponents.Count -eq 0) {
    Write-Timestamped "No components loaded. Nothing to do."
    return
}

Write-Timestamped "Executing monitor with $($loadedComponents.Count) component(s)."
Invoke-PostInstallMonitor -Component $loadedComponents

Write-Timestamped "=== Component loader finished ==="