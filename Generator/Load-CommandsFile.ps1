. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Loads a commands file (.psd1) into a hashtable.

.DESCRIPTION
    Load-CommandsFile is the second stage in the autounattend generator pipeline.
    It receives the full path to a commands file and loads it using
    Import-PowerShellDataFile.

    This function does NOT validate the .psd1 schema. It only ensures that:
        - The file exists
        - The file can be parsed
        - The result is a hashtable

    Schema validation is performed in the next pipeline stage.

.PARAMETER CommandsFilePath
    The full path to the .psd1 commands file.

.OUTPUTS
    Hashtable representing the file content.

.EXAMPLE
    $commands = Load-CommandsFile -CommandsFilePath "C:\Build\ProjA\Commands.psd1"

.NOTES
    This function throws if:
        - The file does not exist
        - The file cannot be parsed
        - The parsed result is not a hashtable
#>
function Load-Manifest {
    param(
        [Parameter(Mandatory)]
        [string] $CommandsFilePath
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Loading commands from '$CommandsFilePath'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Checking if commands file exists")
    if (-not (Test-Path $CommandsFilePath)) {
        throw "Commands file '$CommandsFilePath' does not exist."
    }

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Parsing commands file")
    try {
        $data = Import-PowerShellDataFile -Path $CommandsFilePath
    }
    catch {
        throw "Failed to parse '$CommandsFilePath': $($_.Exception.Message)"
    }

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Validating commands structure")
    if (-not ($data -is [hashtable])) {
        throw "'$CommandsFilePath' did not produce a hashtable."
    }

    Write-Timestamped (Format-Line -Level "INFO" -Message "Commands loaded successfully")
    return $data
}
