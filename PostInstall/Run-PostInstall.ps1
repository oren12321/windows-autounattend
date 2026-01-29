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

Write-Timestamped (Format-Line -Level "Info" -Message "Component loader initializing.")

# Load loader + monitor functions
try {
    . (Join-Path $PSScriptRoot "Monitor\Load-PostInstallComponents.ps1")
    Write-Timestamped (Format-Line -Level "Info" -Message "Loaded Load-PostInstallComponents.ps1")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Failed to load Load-PostInstallComponents.ps1: $_")
    return
}

try {
    . (Join-Path $PSScriptRoot "Monitor\Invoke-PostInstallMonitor.ps1")
    Write-Timestamped (Format-Line -Level "Info" -Message "Loaded Invoke-PostInstallMonitor.ps1")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Failed to load Invoke-PostInstallMonitor.ps1: $_")
    return
}

# Validate components directory
if (-not (Test-Path $ComponentsDirectory)) {
    Write-Timestamped (Format-Line -Level "Error" -Message "Components directory not found: $ComponentsDirectory")
    return
}

# Load components
Write-Timestamped (Format-Line -Level "Info" -Message "Loading components from: $ComponentsDirectory")
$loadedComponents = @()

try {
    $loadedComponents = Load-PostInstallComponents -ComponentsDirectory $ComponentsDirectory
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Exception while loading components: $_")
    return
}

if ($loadedComponents.Count -eq 0) {
    Write-Timestamped (Format-Line -Level "Info" -Message "No components loaded. Nothing to do.")
    return
}

Write-Timestamped (Format-Line -Level "Info" -Message "Loaded $($loadedComponents.Count) component(s). Executing monitor.")

# Run monitor
try {
    Invoke-PostInstallMonitor -Component $loadedComponents
    Write-Timestamped (Format-Line -Level "Info" -Message "Monitor execution completed.")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Monitor execution failed: $_")
}

Write-Timestamped (Format-Line -Level "Info" -Message "Component loader finished.")