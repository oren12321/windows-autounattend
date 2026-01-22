function New-PostInstallComponent {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$StartCondition,

        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [Parameter(Mandatory)]
        [scriptblock]$StopCondition
    )

    @{
        StartCondition = $StartCondition
        Action         = $Action
        StopCondition  = $StopCondition
    }
}
