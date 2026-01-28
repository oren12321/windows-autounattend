function Write-Timestamped {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Information "$timestamp | $Message"
}

function Format-Line {
    param(
        [string]$Level,
        [string]$Source,
        [string]$Component,
        [string]$Message
    )

    $levelPad     = $Level.ToUpper().PadRight(5)
    $sourcePad    = $Source.PadRight(12)
    $componentPad = $Component.PadRight(12)

    "$levelPad | $sourcePad | $componentPad | $Message"
}