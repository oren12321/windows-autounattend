. (Join-Path $PSScriptRoot '..\Utils\Logging.ps1')

function Remove-OrphanPostInstallComponents {

    $indexPath = "HKCU:\Software\PostInstall\Index"

    if (-not (Test-Path $indexPath)) {
        Write-Timestamped (Format-Line -Level "Info" -Message "Index path not found. No orphan cleanup required.")
        return
    }

    $index = Get-ItemProperty -Path $indexPath -ErrorAction SilentlyContinue
    if (-not $index) {
        Write-Timestamped (Format-Line -Level "Info" -Message "Index is empty. No orphan cleanup required.")
        return
    }

    foreach ($property in $index.PSObject.Properties) {

        # Only process entries ending with "_Path"
        if ($property.Name -notlike "*_Path") { continue }

        $componentName = $property.Name -replace "_Path$", ""
        $componentFile = $property.Value

        Write-Timestamped (Format-Line -Level "Info" -Message "Checking component '$componentName' at '$componentFile'")

        if (Test-Path $componentFile) {
            Write-Timestamped (Format-Line -Level "Info" -Message "'$componentName' is valid.")
            continue
        }

        Write-Timestamped (Format-Line -Level "Warning" -Message "'$componentName' is orphaned. Component file missing.")

        # Remove component registry key
        $componentRegistryPath = "HKCU:\Software\PostInstall\Components\$componentName"
        if (Test-Path $componentRegistryPath) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Removing orphan registry key: $componentRegistryPath")
            Remove-Item -Path $componentRegistryPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Remove index entry
        Write-Timestamped (Format-Line -Level "Info" -Message "Removing orphan index entry: $($property.Name)")
        Remove-ItemProperty -Path $indexPath -Name $property.Name -ErrorAction SilentlyContinue
    }
}