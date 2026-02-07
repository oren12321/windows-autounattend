. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Scans a directories tree and discover all Commands.ps1 files.

.DESCRIPTION
    Discover-Commands is the first stage in the autounattend generator pipeline.
    It receives the path to a scripts folder and identifies all directories inside it
    that contains a Commands.psd1 file.

    A valid directory:
        - Inside the scripts folder
        - Contains a Commands.psd1 file
        - Is NOT Shared, Build or .git folder

    The function returns a list of Commands.psd1 file paths and their folder name
    that they are in it (might also represent the project name):
        @{
            Name         = <project folder name>
            CommandsPath = <full path to the commands file>
        }

    This function performs no side effects and does not load the commands content.
    It only discovers direcories structure. Later pipeline stages load and validate
    the commands.

.PARAMETER BuildRoot
    The full path to the directories tree folder.

.OUTPUTS
    An array of hashtables, each describing a discovered command files.

.EXAMPLE
    Discover-Commands -BuildRoot "C:\Repo\Build"

.NOTES
    This function throws if:
        - The root does not exist
#>
function Discover-Commands {
    param(
        [Parameter(Mandatory)]
        [string] $Root
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Discovering commands in root '$Root'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Checking if root exists")
    if (-not (Test-Path $Root)) {
        throw "Root '$Root' does not exist."
    }

    $discovered = @()

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Scanning subdirectories under '$Root'")
    Get-ChildItem -Path $Root -Directory -Recurse | 
        Where-Object { 
            $_.FullName -notlike "*\Shared\*" -and
            $_.FullName -notlike "*\Build\*" -and
            $_.FullName -notlike "*\.git\*" } | ForEach-Object {
                
        $folder = $_
        Write-Timestamped (Format-Line -Level "TRACE" -Message "Inspecting folder '$($folder.Name)'")

        # Find commands file
        $commands = Get-ChildItem -Path $folder.FullName -Filter "Commands.psd1"
        Write-Timestamped (Format-Line -Level "TRACE" -Message "Found $($commands.Count) command file(s) in '$($folder.Name)'")

        # Must contain exactly one manifest
        if ($commands.Count -ne 1) {
            Write-Timestamped (Format-Line -Level "TRACE" -Message "Folder '$($folder.Name)' does not contain exactly one command files. Skipping")
            return
        }

        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Valid commands folder discovered: '$($folder.Name)'")

        $discovered += @{
            Name         = $folder.Name
            CommandsPath = $commands[0].FullName
        }
    }

    Write-Timestamped (Format-Line -Level "INFO" -Message "Commands discovery complete. Total found: $($discovered.Count)")
    return ,$discovered
}
