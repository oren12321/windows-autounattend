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

    $result = @{
        Specialize  = @()
        FirstLogon  = @()
        ActiveSetup = @()
    }

    foreach ($cmd in $NormalizedCommands) {
        switch ($cmd.Pass) {
            "Specialize"  { $result.Specialize  += $cmd }
            "FirstLogon"  { $result.FirstLogon  += $cmd }
            "ActiveSetup" { $result.ActiveSetup += $cmd }
        }
    }

    # Sort each group by Order
    $result.Specialize = @($result.Specialize | Sort-Object -Property { $_.Order })
    $result.FirstLogon =  @($result.FirstLogon | Sort-Object -Property { $_.Order })
    $result.ActiveSetup = @($result.ActiveSetup | Sort-Object -Property { $_.Order })

    return $result
}
