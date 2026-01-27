param(
    [string] $ComponentsDirectory = (Join-Path $PSScriptRoot "Components")
)

# Load logging
try {
    . (Join-Path $PSScriptRoot "Utils\Logging.ps1")
}
catch {
    Write-Output "FATAL: Failed to load Logging.ps1: $_"
    return
}

Write-Timestamped "Component loader initializing."

# Load loader + monitor functions
try {
    . (Join-Path $PSScriptRoot "Monitor\Load-PostInstallComponents.ps1")
    Write-Timestamped "Loaded Load-PostInstallComponents.ps1"
}
catch {
    Write-Timestamped "ERROR: Failed to load Load-PostInstallComponents.ps1: $_"
    return
}

try {
    . (Join-Path $PSScriptRoot "Monitor\Invoke-PostInstallMonitor.ps1")
    Write-Timestamped "Loaded Invoke-PostInstallMonitor.ps1"
}
catch {
    Write-Timestamped "ERROR: Failed to load Invoke-PostInstallMonitor.ps1: $_"
    return
}

# Validate components directory
if (-not (Test-Path $ComponentsDirectory)) {
    Write-Timestamped "ERROR: Components directory not found: $ComponentsDirectory"
    return
}

# Load components
Write-Timestamped "Loading components from: $ComponentsDirectory"
$loadedComponents = @()

try {
    $loadedComponents = Load-PostInstallComponents -ComponentsDirectory $ComponentsDirectory
}
catch {
    Write-Timestamped "ERROR: Exception while loading components: $_"
    return
}

if ($loadedComponents.Count -eq 0) {
    Write-Timestamped "No components loaded. Nothing to do."
    return
}

Write-Timestamped "Loaded $($loadedComponents.Count) component(s). Executing monitor."

# Run monitor
try {
    Invoke-PostInstallMonitor -Component $loadedComponents
    Write-Timestamped "Monitor execution completed."
}
catch {
    Write-Timestamped "ERROR: Monitor execution failed: $_"
}

Write-Timestamped "Component loader finished."