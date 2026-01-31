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

function Add-RotatingLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [long]$MaxSize = 0, # Recommended value: 5MB
        [int]$MaxFiles = 0, # Recommended value: 5
        
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $Logs
    )
    # Append logs to log file
    Add-Content -Path $Path -Value $Logs
    
    # Rotate if needed
    if ($MaxSize -gt 0) {
        if ((Test-Path $Path) -and (Get-Item $Path).Length -gt $MaxSize) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            Rename-Item $Path "$Path.$timestamp"
        }
    }
    
    # Enforce retention
    if ($MaxFiles -gt 0) {
        $directory = Split-Path $Path
        $filename = $(Split-Path $Path -Leaf)
        $files = Get-ChildItem $directory -Filter "$filename.*" `
            | Where-Object { $_.Name -match '\.\d{8}_\d{6}$' } `
            | Sort-Object LastWriteTime -Descending

        if ($files.Count -gt $MaxFiles) {
            $files | Select-Object -Skip $MaxFiles | Remove-Item -Force
        }
    }
}