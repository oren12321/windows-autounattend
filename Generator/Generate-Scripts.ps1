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

    Write-Information "[INFO] Generating pass-specific scripts in '$OutputFolder'"

    Write-Information "[DEBUG] Ensuring output folder exists"
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        Write-Information "[DEBUG] Created output folder '$OutputFolder'"
    }

    $result = @{
        SpecializeScript  = $null
        FirstLogonScript  = $null
        ActiveSetupScript = $null
    }

    foreach ($pass in @("Specialize", "FirstLogon", "ActiveSetup")) {
        Write-Information "[DEBUG] Processing pass '$pass'"

        $commands = $Groups[$pass]

        $path = Join-Path $OutputFolder "$pass.ps1"
        Write-Information "[DEBUG] Creating script file '$path'"

        $content = @(
            "# Auto-generated script for $pass"
            ""
        )

        $cmdIndex = 0
        foreach ($cmd in $commands) {
            $cmdIndex++
            Write-Information "[TRACE] Adding command #$cmdIndex from project '$($cmd.Project)' to $pass script"
            $content += $cmd.Command
        }

        $content -join "`r`n" | Set-Content -Path $path -Encoding UTF8

        Write-Information "[INFO] Script for pass '$pass' written to '$path'"

        $result["${pass}Script"] = $path
    }

    Write-Information "[INFO] Script generation complete"
    return $result
}
