. (Join-Path $PSScriptRoot '..\Utils\Logging.ps1')

function Load-PostInstallComponents {
    param(
        [Parameter(Mandatory)]
        [string] $ComponentsDirectory
    )

    $loaded = @()

    if (-not (Test-Path $ComponentsDirectory)) {
        Write-Timestamped (Format-Line -Level "Error" -Message "Components directory not found: $ComponentsDirectory")
        return $loaded
    }

    Write-Timestamped (Format-Line -Level "Info" -Message "Loading components from folder: $ComponentsDirectory")

    $files = Get-ChildItem -Path $ComponentsDirectory -Filter *.ps1 | Sort-Object Name

    if ($files.Count -eq 0) {
        Write-Timestamped (Format-Line -Level "Warning" -Message "No component files (*.ps1) found in: $ComponentsDirectory")
        return $loaded
    }

    foreach ($file in $files) {
        Write-Timestamped (Format-Line -Level "Info" -Message "Loading component file: $($file.Name)")

        try {
            # Dot-source the component file
            . $file.FullName
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Exception while dot-sourcing '$($file.Name)': $_")
            continue
        }
        
        # Validate that the file defined $Component
        if (-not $Component) {
            Write-Timestamped (Format-Line -Level "Error" -Message "Component file '$($file.Name)' did not define a `$Component variable. Skipping.")
            continue
        }
        
        # Validate required scriptblocks
        $missing = @()
        if (-not ($Component.StartCondition -is [scriptblock])) { $missing += "StartCondition" }
        if (-not ($Component.Action         -is [scriptblock])) { $missing += "Action" }
        if (-not ($Component.StopCondition  -is [scriptblock])) { $missing += "StopCondition" }

        if ($missing.Count -gt 0) {
            Write-Timestamped (Format-Line -Level "Error" -Message "Component '$($file.Name)' missing required scriptblocks: $($missing -join ', '). Skipping.")
            continue
        }

        # Component is valid
        $loaded += $Component
        Write-Timestamped (Format-Line -Level "Info" -Message "Component '$($file.Name)' loaded successfully.")

        # Clean up for next iteration
        Remove-Variable Component -ErrorAction SilentlyContinue
    }

    return ,$loaded
}