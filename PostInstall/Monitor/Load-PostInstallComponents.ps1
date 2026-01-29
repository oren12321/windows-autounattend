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
        if (-not ($Component.RegistryPath   -is [string]))      { $missing += "RegistryPath" }

        if ($missing.Count -gt 0) {
            Write-Timestamped (Format-Line -Level "Error" -Message "Component '$($file.Name)' missing required scriptblocks: $($missing -join ', '). Skipping.")
            continue
        }

        # Create component registry key
        $componentRegistryPath = "HKCU:\Software\PostInstall\Components\$($Component.Name)"
        if (-not (Test-Path $componentRegistryPath)) {
            Write-Timestamped (Format-Line -Level "Info" -Message "Creating $componentRegistryPath")
            try {
                New-Item -Path $componentRegistryPath -Force | Out-Null
            }
            catch {
                Write-Timestamped (Format-Line -Level "Error" -Message "Failed to create ${componentRegistryPath}: $_")
                continue
            }
        }
        
        # Save component path
        $indexRegistryPath = "HKCU:\Software\PostInstall\Index"
        try {
            Write-Timestamped (Format-Line -Level "Info" -Message "Saving $($Component.Name)_Path=$($file.FullName) in $indexRegistryPath")
            if (-not (Get-ItemProperty -Path $indexRegistryPath -Name "$($Component.Name)_Path" -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $indexRegistryPath -Name "$($Component.Name)_Path" -Value "$($file.FullName)" -PropertyType String -Force | Out-Null
            } else {
                Set-ItemProperty -Path $indexRegistryPath -Name "$($Component.Name)_Path" -Value "$($file.FullName)" -Force
            }
        }
        catch {
            Write-Timestamped (Format-Line -Level "Error" -Message "Failed to save $($Component.Name)_Path=$($file.FullName) in ${indexRegistryPath}: $_")
            Write-Timestamped (Format-Line -Level "Info" -Message "Removing $componentRegistryPath")
            
            Remove-Item -Path $componentRegistryPath -Recurse -Force -ErrorAction SilentlyContinue
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