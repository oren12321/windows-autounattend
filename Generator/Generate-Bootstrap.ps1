. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Generates the Specialize-phase bootstrap script.

.DESCRIPTION
    Generate-Bootstrap is the ninth stage in the autounattend generator pipeline.
    It creates a PowerShell script that will run during the Specialize pass.
    The script performs three tasks:

        1. Creates the workspace directory
        2. Extracts Build.zip into the workspace
        3. Executes the extracted Specialize.ps1 script

.PARAMETER OutputFolder
    Folder where Bootstrap.ps1 will be written.

.PARAMETER WorkspacePath
    The path where Build.zip should be extracted.

.PARAMETER ZipPath
    The path to Build.zip as it will exist on the target machine.

.PARAMETER SpecializeScriptPath
    The path to Specialize.ps1 inside the extracted workspace.

.OUTPUTS
    The full path to Bootstrap.ps1.

.EXAMPLE
    Generate-Bootstrap -OutputFolder "C:\Build" `
                       -WorkspacePath "C:\Workspace" `
                       -ZipPath "C:\Windows\Setup\Scripts\Build.zip" `
                       -SpecializeScriptPath "C:\Workspace\Specialize.ps1"
#>
function Generate-Bootstrap {
    param(
        [Parameter(Mandatory)]
        [string] $OutputFolder,

        [Parameter(Mandatory)]
        [string] $WorkspacePath,

        [Parameter(Mandatory)]
        [string] $ZipPath,

        [Parameter(Mandatory)]
        [string] $SpecializeScriptPath
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Generating bootstrap script in '$OutputFolder'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Ensuring output folder exists")
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Created output folder '$OutputFolder'")
    }

    $bootstrapPath = Join-Path $OutputFolder "Bootstrap.ps1"
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Bootstrap script path resolved to '$bootstrapPath'")

    Write-Timestamped (Format-Line -Level "TRACE" -Message "Preparing bootstrap script content")
    $content = @"
# Auto-generated bootstrap script
New-Item -ItemType Directory -Path "$WorkspacePath" -Force | Out-Null
Expand-Archive -Path "$ZipPath" -DestinationPath "$WorkspacePath" -Force
& "$SpecializeScriptPath"
"@

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Writing bootstrap script to '$bootstrapPath'")
    $content | Set-Content -Path $bootstrapPath -Encoding UTF8

    Write-Timestamped (Format-Line -Level "INFO" -Message "Bootstrap script generated successfully")

    return $bootstrapPath
}
