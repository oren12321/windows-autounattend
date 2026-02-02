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

    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    $result = @{
        SpecializeScript  = $null
        FirstLogonScript  = $null
        ActiveSetupScript = $null
    }

    foreach ($pass in @("Specialize", "FirstLogon", "ActiveSetup")) {
        $commands = $Groups[$pass]

        if ($commands.Count -eq 0) { continue }

        $path = Join-Path $OutputFolder "$pass.ps1"

        $content = @(
            "# Auto-generated script for $pass"
            ""
        )

        foreach ($cmd in $commands) {
            $content += $cmd.Command
        }

        $content -join "`r`n" | Set-Content -Path $path -Encoding UTF8

        $result["${pass}Script"] = $path
    }

    return $result
}
