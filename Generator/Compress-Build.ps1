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

    if (-not (Test-Path $BuildRoot)) {
        throw "Build root '$BuildRoot' does not exist."
    }

    $zipDir = Split-Path $OutputZipPath -Parent
    if (-not (Test-Path $zipDir)) {
        New-Item -ItemType Directory -Path $zipDir | Out-Null
    }

    if (Test-Path $OutputZipPath) {
        Remove-Item -Path $OutputZipPath -Force
    }

    Compress-Archive -Path (Join-Path $BuildRoot '*') -DestinationPath $OutputZipPath

    return $OutputZipPath
}
