<#
.SYNOPSIS
    Validates the structure and schema of a project manifest.

.DESCRIPTION
    Validate-Manifest is the third stage in the autounattend generator pipeline.
    It receives a manifest hashtable (already loaded from disk) and ensures that
    it conforms to the required schema.

    Required structure:
        - Manifest must contain a "Commands" key
        - Commands must be an array
        - Each command must be a hashtable containing:
            Pass    = "Specialize" | "FirstLogon" | "ActiveSetup"
            Order   = integer
            Command = non-empty string

    This function does not modify the manifest. It only validates it.

.PARAMETER Manifest
    The manifest hashtable loaded from the .psd1 file.

.PARAMETER ProjectName
    The name of the project, used for clearer error messages.

.OUTPUTS
    The same manifest hashtable, unchanged.

.EXAMPLE
    Validate-Manifest -Manifest $data -ProjectName "ProjA"

.NOTES
    This function throws on any validation failure.
#>
function Validate-Manifest {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Manifest,

        [Parameter(Mandatory)]
        [string] $ProjectName
    )

    if (-not $Manifest.ContainsKey("Commands")) {
        throw "Project '$ProjectName' manifest is missing the 'Commands' key."
    }

    $commands = $Manifest.Commands

    if (-not ($commands -is [System.Collections.IEnumerable])) {
        throw "Project '$ProjectName' manifest 'Commands' must be an array."
    }

    foreach ($cmd in $commands) {
        if (-not ($cmd -is [hashtable])) {
            throw "Project '$ProjectName' contains a command entry that is not a hashtable."
        }

        foreach ($key in @("Pass", "Order", "Command")) {
            if (-not $cmd.ContainsKey($key)) {
                throw "Project '$ProjectName' command entry is missing required key '$key'."
            }
        }

        $validPasses = @("Specialize", "FirstLogon", "ActiveSetup")
        if ($cmd.Pass -notin $validPasses) {
            throw "Project '$ProjectName' has invalid Pass value '$($cmd.Pass)'."
        }

        if (-not ($cmd.Order -is [int])) {
            throw "Project '$ProjectName' command Order must be an integer."
        }

        if ([string]::IsNullOrWhiteSpace($cmd.Command)) {
            throw "Project '$ProjectName' command text cannot be empty."
        }
    }

    return $Manifest
}
