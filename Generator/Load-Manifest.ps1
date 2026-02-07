<#
.SYNOPSIS
    Loads a project manifest (.psd1) into a hashtable.

.DESCRIPTION
    Load-Manifest is the second stage in the autounattend generator pipeline.
    It receives the full path to a project manifest file and loads it using
    Import-PowerShellDataFile.

    This function does NOT validate the manifest schema. It only ensures that:
        - The file exists
        - The file can be parsed
        - The result is a hashtable

    Schema validation is performed in the next pipeline stage.

.PARAMETER ManifestPath
    The full path to the .psd1 manifest file.

.OUTPUTS
    Hashtable representing the manifest content.

.EXAMPLE
    $manifest = Load-Manifest -ManifestPath "C:\Build\ProjA\ProjA.psd1"

.NOTES
    This function throws if:
        - The file does not exist
        - The file cannot be parsed
        - The parsed result is not a hashtable
#>
function Load-Manifest {
    param(
        [Parameter(Mandatory)]
        [string] $ManifestPath
    )

    Write-Information "[INFO] Loading manifest from '$ManifestPath'"

    Write-Information "[DEBUG] Checking if manifest file exists"
    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest file '$ManifestPath' does not exist."
    }

    Write-Information "[DEBUG] Parsing manifest file"
    try {
        $data = Import-PowerShellDataFile -Path $ManifestPath
    }
    catch {
        throw "Failed to parse manifest '$ManifestPath': $($_.Exception.Message)"
    }

    Write-Information "[DEBUG] Validating manifest structure"
    if (-not ($data -is [hashtable])) {
        throw "Manifest '$ManifestPath' did not produce a hashtable."
    }

    Write-Information "[INFO] Manifest loaded successfully"
    return $data
}
