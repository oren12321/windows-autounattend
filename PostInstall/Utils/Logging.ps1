function Write-Timestamped {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Information "$timestamp | $Message"
}

function Format-Line {
    param(
        [string]$Level,
        [string]$Message
    )

    # Caller info
    $inv = Get-PSCallStack | Select-Object -Skip 1 -First 1

    # Function name
    $func = if ($inv.FunctionName -and $inv.FunctionName -ne '<ScriptBlock>') {
        $inv.FunctionName
    } else {
        '<prompt>'
    }

    # File name + line number
    if ($inv.ScriptName) {
        $file = Split-Path $inv.ScriptName -Leaf
        $line = $inv.ScriptLineNumber
        $fileInfo = "${file}:${line}"
    } else {
        $fileInfo = '<interactive>'
    }

    # Padding
    $levelPad = $Level.ToUpper().PadRight(5)
    $funcPad  = $func.PadRight(20)
    $filePad  = $fileInfo.PadRight(25)

    "$levelPad | $funcPad | $filePad | $Message"
}
