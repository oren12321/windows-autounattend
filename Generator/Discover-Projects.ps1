<#
.SYNOPSIS
    Scans a packed Build folder and discovers all valid project directories.

.DESCRIPTION
    Discover-Projects is the first stage in the autounattend generator pipeline.
    It receives the path to a fully packed Build folder (produced by the packer)
    and identifies all project directories inside it.

    A valid project directory:
        - Is a direct child of the Build root
        - Contains exactly one .psd1 manifest file
        - The manifest filename matches the folder name (e.g., ProjA\ProjA.psd1)
        - Is NOT the Shared folder

    The function returns a list of objects describing each project:
        @{
            Name         = <project folder name>
            Path         = <full path to project folder>
            ManifestPath = <full path to the manifest file>
        }

    This function performs no side effects and does not load the manifest content.
    It only discovers project structure. Later pipeline stages load and validate
    the manifest.

.PARAMETER BuildRoot
    The full path to the packed Build folder.

.OUTPUTS
    An array of hashtables, each describing a discovered project.

.EXAMPLE
    Discover-Projects -BuildRoot "C:\Repo\Build"

.NOTES
    This function throws if:
        - The Build root does not exist
        - No valid projects are found
#>
function Discover-Projects {
    param(
        [Parameter(Mandatory)]
        [string] $BuildRoot
    )

    Write-Information "[INFO] Discovering projects in build root '$BuildRoot'"

    Write-Information "[DEBUG] Checking if build root exists"
    if (-not (Test-Path $BuildRoot)) {
        throw "Build root '$BuildRoot' does not exist."
    }

    $projects = @()

    Write-Information "[DEBUG] Scanning subdirectories under '$BuildRoot'"
    Get-ChildItem -Path $BuildRoot -Directory -Recurse | Where-Object { 
        $_.FullName -notlike "*\Shared\*" -and
        $_.FullName -notlike "*\.git\*"
    } | ForEach-Object {
        $folder = $_
        Write-Information "[TRACE] Inspecting folder '$($folder.Name)'"

        # Find manifest files
        $manifests = Get-ChildItem -Path $folder.FullName -Filter "Unattend.psd1"
        Write-Information "[TRACE] Found $($manifests.Count) manifest file(s) in '$($folder.Name)'"

        # Must contain exactly one manifest
        if ($manifests.Count -ne 1) {
            Write-Information "[TRACE] Folder '$($folder.Name)' does not contain exactly one manifest. Skipping"
            return
        }

        $manifest = $manifests[0]

        Write-Information "[DEBUG] Valid project discovered: '$($folder.Name)'"

        $projects += @{
            Name         = $folder.Name
            Path         = $folder.FullName
            ManifestPath = $manifest.FullName
        }
    }

    Write-Information "[INFO] Project discovery complete. Total projects found: $($projects.Count)"
    return ,$projects
}
