. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Generates PowerShell scripts for each deployment pass.

.DESCRIPTION
    Generate-Scripts is the sixth stage in the autounattend generator pipeline.
    It receives grouped commands and writes three PowerShell scripts:

        Specialize.ps1
        FirstLogon.ps1
        ActiveSetup.ps1

    Each script contains the commands for that pass in sorted order.

.PARAMETER Groups
    Hashtable with keys:
        Specialize, FirstLogon, ActiveSetup

.PARAMETER OutputFolder
    Folder where the scripts will be written.

.OUTPUTS
    Hashtable with keys:
        SpecializeScript
        FirstLogonScript
        ActiveSetupScript

    Each value is either a file path or $null if no script was generated.

.EXAMPLE
    $scripts = Generate-Scripts -Groups $groups -OutputFolder "C:\Build"
#>
function Generate-Scripts {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Groups,

        [Parameter(Mandatory)]
        [string] $OutputFolder
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Generating pass-specific scripts in '$OutputFolder'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Ensuring output folder exists")
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Created output folder '$OutputFolder'")
    }

    $result = @{
        SpecializeScript  = $null
        FirstLogonScript  = $null
        ActiveSetupScript = $null
    }

    foreach ($pass in @("Specialize", "FirstLogon", "ActiveSetup")) {
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Processing pass '$pass'")

        $commands = $Groups[$pass]

        if ($commands.Count -eq 0) {
            Write-Timestamped (Format-Line -Level "INFO" -Message "No commands found for pass '$pass'. Skipping script generation")
            continue
        }

        $path = Join-Path $OutputFolder "$pass.ps1"
        Write-Timestamped (Format-Line -Level "DEBUG" -Message "Creating script file '$path'")

        $content = @(
            "# Auto-generated script for $pass"
            ""
        )

        $cmdIndex = 0
        foreach ($cmd in $commands) {
            $cmdIndex++
            Write-Timestamped (Format-Line -Level "TRACE" -Message "Adding command #$cmdIndex from project '$($cmd.Project)' to $pass script")
            $content += $cmd.Command
        }

        $content -join "`r`n" | Set-Content -Path $path -Encoding UTF8

        Write-Timestamped (Format-Line -Level "INFO" -Message "Script for pass '$pass' written to '$path'")

        $result["${pass}Script"] = $path
    }

    Write-Timestamped (Format-Line -Level "INFO" -Message "Script generation complete")
    return $result
}
