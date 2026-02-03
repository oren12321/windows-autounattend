. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Compresses the Build folder into a ZIP archive.

.DESCRIPTION
    Compress-Build is the seventh stage in the autounattend generator pipeline.
    It receives the path to the packed Build folder and produces a ZIP archive
    containing all files and subfolders.

    The ZIP file will later be embedded into autounattend.xml.

.PARAMETER BuildRoot
    The full path to the packed Build folder.

.PARAMETER OutputZipPath
    The full path where the ZIP file should be created.

.OUTPUTS
    String containing the full path to the created ZIP file.

.EXAMPLE
    Compress-Build -BuildRoot "C:\Build" -OutputZipPath "C:\Build.zip"

.NOTES
    This function overwrites the ZIP file if it already exists.
#>
function Compress-Build {
    param(
        [Parameter(Mandatory)]
        [string] $BuildRoot,

        [Parameter(Mandatory)]
        [string] $OutputZipPath
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Compressing build root '$BuildRoot' into '$OutputZipPath'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Checking if build root exists")
    if (-not (Test-Path $BuildRoot)) {
        throw "Build root '$BuildRoot' does not exist."
    }

    $zipDir = Split-Path $OutputZipPath -Parent
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Ensuring output directory '$zipDir' exists")
    if (-not (Test-Path $zipDir)) {
        New-Item -ItemType Directory -Path $zipDir | Out-Null
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Created directory '$zipDir'")
    }

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Checking for existing ZIP file at '$OutputZipPath'")
    if (Test-Path $OutputZipPath) {
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Existing ZIP found. Removing old file")
        Remove-Item -Path $OutputZipPath -Force
    }

    Write-Timestamped (Format-Line -Level "INFO" -Message "Creating ZIP archive")
    Compress-Archive -Path (Join-Path $BuildRoot '*') -DestinationPath $OutputZipPath

    Write-Timestamped (Format-Line -Level "INFO" -Message "Build compression complete. Output ZIP: '$OutputZipPath'")
    return $OutputZipPath
}
