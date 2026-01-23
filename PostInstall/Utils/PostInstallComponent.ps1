function New-PostInstallComponent {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$StartCondition,

        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [Parameter(Mandatory)]
        [scriptblock]$StopCondition,

        # Optional: component name (used for registry scoping, logging, ordering, etc.)
        [string]$Name = $null
    )

    # If no name provided, generate a stable anonymous name
    if (-not $Name) {
        $Name = "Component_" + ([guid]::NewGuid().ToString())
    }

    [pscustomobject]@{
        Name           = $Name
        StartCondition = $StartCondition
        Action         = $Action
        StopCondition  = $StopCondition
    }
}
