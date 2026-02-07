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

    Write-Information "[INFO] Validating manifest for project '$ProjectName'"

    # Check for Commands key
    Write-Information "[DEBUG] Checking for 'Commands' key"
    if (-not $Manifest.ContainsKey("Commands")) {
        throw "Project '$ProjectName' manifest is missing the 'Commands' key."
    }

    $commands = $Manifest.Commands

    # Validate Commands is an array
    Write-Information "[DEBUG] 'Commands' key found. Validating type"
    if (-not ($commands -is [System.Collections.IEnumerable])) {
        throw "Project '$ProjectName' manifest 'Commands' must be an array."
    }

    Write-Information "[INFO] Validating command entries"

    $index = 0
    foreach ($cmd in $commands) {
        $index++
        Write-Information "[DEBUG] Validating command entry #$index"

        if (-not ($cmd -is [hashtable])) {
            throw "Project '$ProjectName' contains a command entry that is not a hashtable."
        }

        foreach ($key in @("Pass", "Order", "Command")) {
            Write-Information "[TRACE] Checking required key '$key' in command #$index"
            if (-not $cmd.ContainsKey($key)) {
                throw "Project '$ProjectName' command entry #$index is missing required key '$key'."
            }
        }

        # Validate Pass
        $validPasses = @("Specialize", "FirstLogon", "ActiveSetup")
        Write-Information "[TRACE] Validating Pass value '$($cmd.Pass)' in command #$index"
        if ($cmd.Pass -notin $validPasses) {
            throw "Project '$ProjectName' has invalid Pass value '$($cmd.Pass)' in command #$index."
        }

        # Validate Order
        Write-Information "[TRACE] Validating Order type in command #$index"
        if (-not ($cmd.Order -is [int])) {
            throw "Project '$ProjectName' command #$index Order must be an integer."
        }

        # Validate Command text
        Write-Information "[TRACE] Validating Command text in command #$index"
        if ([string]::IsNullOrWhiteSpace($cmd.Command)) {
            throw "Project '$ProjectName' command #$index text cannot be empty."
        }

        Write-Information "[INFO] Command #$index validated successfully"
    }

    Write-Information "[INFO] Manifest for '$ProjectName' successfully validated"
    return $Manifest
}
