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

# Load creator + scanner + loader + monitor functions
try {
    . (Join-Path $PSScriptRoot "Monitor\Create-PostInstallRegistry.ps1")
    Write-Timestamped (Format-Line -Level "Info" -Message "Loaded Create-PostInstallRegistry.ps1")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Failed to load Create-PostInstallRegistry.ps1: $_")
    return
}

try {
    . (Join-Path $PSScriptRoot "Monitor\Remove-OrphanPostInstallComponents.ps1")
    Write-Timestamped (Format-Line -Level "Info" -Message "Loaded Remove-OrphanPostInstallComponents.ps1")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Failed to load Remove-OrphanPostInstallComponents.ps1: $_")
    return
}

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

try {
    
    Create-PostInstallRegistry
    Write-Timestamped (Format-Line -Level "Info" -Message "Registry creation completed.")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Exception while creating registry: $_")
    return
}

try {
    
    Remove-OrphanPostInstallComponents
    Write-Timestamped (Format-Line -Level "Info" -Message "Orphan components removal completed.")
}
catch {
    Write-Timestamped (Format-Line -Level "Error" -Message "Exception while removing orphan components: $_")
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