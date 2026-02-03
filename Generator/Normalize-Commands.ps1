. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Flattens all project commands into a normalized list.

.DESCRIPTION
    Normalize-Commands is the fourth stage in the autounattend generator pipeline.
    It receives a list of project objects, each containing a validated manifest,
    and produces a flat list of normalized command entries.

    Each normalized entry contains:
        - Project : the project name
        - Pass    : the deployment pass (Specialize, FirstLogon, ActiveSetup)
        - Order   : execution order within the pass
        - Command : the command string to execute

    This function does not modify the original manifests and does not sort the
    commands. Sorting is performed in the next pipeline stage.

.PARAMETER Projects
    An array of project objects, each containing:
        Name
        Path
        ManifestPath
        Manifest (hashtable)

.OUTPUTS
    An array of normalized command hashtables.

.EXAMPLE
    $normalized = Normalize-Commands -Projects $projects

.NOTES
    This function assumes manifests have already been validated.
#>
function Normalize-Commands {
    param(
        [Parameter(Mandatory)]
        [array] $Projects
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Normalizing commands from all projects")

    $result = @()
    $projectIndex = 0

    foreach ($proj in $Projects) {
        $projectIndex++
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Processing project #$projectIndex ('$($proj.Name)')")

        if (-not $proj.Manifest.ContainsKey("Commands")) {
            throw "Project '$($proj.Name)' manifest contains no Commands."
        }

        $cmdIndex = 0
        foreach ($cmd in $proj.Manifest.Commands) {
            $cmdIndex++
            Write-Timestamped (Format-Line -Level "TRACE" -Message "Normalizing command #$cmdIndex from project '$($proj.Name)'")

            $result += @{
                Project = $proj.Name
                Pass    = $cmd.Pass
                Order   = $cmd.Order
                Command = $cmd.Command
            }
        }

        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Completed processing project '$($proj.Name)'")
    }

    Write-Timestamped (Format-Line -Level "INFO" -Message "Command normalization complete. Total commands: $($result.Count)")

    return ,$result
}
