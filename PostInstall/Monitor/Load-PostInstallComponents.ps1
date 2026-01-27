. (Join-Path $PSScriptRoot '..\Utils\Logging.ps1')

function Load-PostInstallComponents {
    param(
        [Parameter(Mandatory)]
        [string] $ComponentsDirectory
    )

    $loaded = @()

    if (-not (Test-Path $ComponentsDirectory)) {
        Write-Timestamped "Components directory not found: $ComponentsDirectory"
        return $loaded
    }

    Write-Timestamped "Loading components from folder: $ComponentsDirectory"

    $files = Get-ChildItem -Path $ComponentsDirectory -Filter *.ps1 | Sort-Object Name

    foreach ($file in $files) {
        Write-Timestamped "Loading component file: $($file.Name)"

        try {
            . $file.FullName

            if (-not $Component) {
                Write-Timestamped "ERROR: Component file '$($file.Name)' did not define a `$Component variable. Skipping."
                continue
            }

            if (-not ($Component.StartCondition -is [scriptblock] -and
                      $Component.Action         -is [scriptblock] -and
                      $Component.StopCondition  -is [scriptblock])) {

                Write-Timestamped "ERROR: Component '$($file.Name)' is missing required scriptblocks. Skipping."
                continue
            }

            $loaded += $Component
            Write-Timestamped "Component '$($file.Name)' loaded successfully."
        }
        catch {
            Write-Timestamped "ERROR: Failed to load component '$($file.Name)': $_"
        }

        Remove-Variable Component -ErrorAction SilentlyContinue
    }

    return $loaded
}