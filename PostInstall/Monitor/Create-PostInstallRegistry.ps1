. (Join-Path $PSScriptRoot '..\Utils\Logging.ps1')

function Create-PostInstallRegistry {
    
    $componentsPath = "HKCU:\Software\PostInstall\Components"
    
    if (-not (Test-Path $componentsPath)) {
        Write-Timestamped (Format-Line -Level "Info" -Message "Creating $componentsPath")
        try {
            New-Item -Path $componentsPath -Force | Out-Null
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Failed to create ${componentsPath}: $_")
            return
        }
    }
    
    $indexPath = "HKCU:\Software\PostInstall\Index"
    
    if (-not (Test-Path $indexPath)) {
        Write-Timestamped (Format-Line -Level "Info" -Message "Creating $indexPath")
        try {
            New-Item -Path $indexPath -Force | Out-Null
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Failed to create ${indexPath}: $_")
            return
        }
    }
}