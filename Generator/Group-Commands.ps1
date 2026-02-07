<#
.SYNOPSIS
    Groups normalized commands by deployment pass and sorts them.

.DESCRIPTION
    Group-Commands is the fifth stage in the autounattend generator pipeline.
    It receives a flat list of normalized command entries and produces a
    structured hashtable containing three arrays:

        - Specialize
        - FirstLogon
        - ActiveSetup

    Each array is sorted by the Order value.

.PARAMETER NormalizedCommands
    An array of normalized command hashtables, each containing:
        Project, Pass, Order, Command

.OUTPUTS
    Hashtable with keys:
        Specialize, FirstLogon, ActiveSetup

.EXAMPLE
    $groups = Group-Commands -NormalizedCommands $normalized

.NOTES
    This function does not modify the input array.
#>
function Group-Commands {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory)]
        [array] $NormalizedCommands
    )

    Write-Information "[INFO] Grouping normalized commands by pass"

    $result = @{
        Specialize  = @()
        FirstLogon  = @()
        ActiveSetup = @()
    }

    $index = 0
    foreach ($cmd in $NormalizedCommands) {
        $index++
        Write-Information "[DEBUG] Processing command #$index (Project: $($cmd.Project), Pass: $($cmd.Pass))"

        switch ($cmd.Pass) {
            "Specialize" {
                Write-Information "[TRACE] Adding command #$index to Specialize group"
                $result.Specialize += $cmd
            }
            "FirstLogon" {
                Write-Information "[TRACE] Adding command #$index to FirstLogon group"
                $result.FirstLogon += $cmd
            }
            "ActiveSetup" {
                Write-Information "[TRACE] Adding command #$index to ActiveSetup group"
                $result.ActiveSetup += $cmd
            }
        }
    }

    Write-Information "[DEBUG] Sorting command groups by Order value"

    if ($index -gt 0) {
        $result.Specialize  = @($result.Specialize  | Sort-Object -Property { $_.Order })
        $result.FirstLogon  = @($result.FirstLogon  | Sort-Object -Property { $_.Order })
        $result.ActiveSetup = @($result.ActiveSetup | Sort-Object -Property { $_.Order })
    }

    Write-Information "[INFO] Grouping complete. Specialize: $($result.Specialize.Count), FirstLogon: $($result.FirstLogon.Count), ActiveSetup: $($result.ActiveSetup.Count)"

    return $result
}
