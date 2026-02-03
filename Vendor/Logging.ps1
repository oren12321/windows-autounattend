function Write-Timestamped {
    param([string]$Message)

    if (-not $Message) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Information "$timestamp | $Message"
}

function Format-Line {
    param(
        [string]$Level,
        [string]$Message
    )

    # Normalize level
    $normalizedLevel = $Level.ToUpper()

    # Caller info
    $inv = Get-PSCallStack | Select-Object -Skip 1 -First 1
    $scriptName = $null

    if ($inv.ScriptName) {
        $scriptName = (Split-Path $inv.ScriptName -Leaf).Split('.')[0]
    }

    # Build per-file filter variable name
    $fileFilterVar = if ($scriptName) { "${scriptName}_LevelFilter" } else { $null }

    # 1. Try per-file filter (search all scopes)
    $filter = $null
    if ($fileFilterVar) {
        try {
            $filter = (Get-Variable -Name $fileFilterVar -ErrorAction Stop).Value
        } catch { }
    }

    # 2. If not found, try global LevelFilter
    if ($null -eq $filter) {
        try {
            $filter = (Get-Variable -Name LevelFilter -ErrorAction Stop).Value
        } catch { }
    }

    # 3. Normalize filter into:
    #    $null → no filter (print everything)
    #    @()   → empty filter (print nothing)
    #    @(...) → list of allowed levels
    if ($null -eq $filter) {
        $effectiveFilter = $null
    }
    elseif ($filter -is [System.Collections.IList]) {
        # Already a list/array (including empty)
        $effectiveFilter = @($filter)
    }
    else {
        # Single value → wrap it
        $effectiveFilter = @($filter)
    }

    # 4. Empty array → block all logs
    if ($effectiveFilter -is [System.Collections.IList] -and $effectiveFilter.Count -eq 0) {
        return $null
    }

    # 5. If we have a filter and this level is not allowed → skip
    if ($effectiveFilter -is [System.Collections.IList] -and $effectiveFilter -notcontains $normalizedLevel) {
        return $null
    }
    
    # Function name
    $func = if ($inv.FunctionName -and $inv.FunctionName -ne '<ScriptBlock>') {
        $inv.FunctionName
    } else {
        '<prompt>'
    }

    # File + line info
    if ($inv.ScriptName) {
        $file = Split-Path $inv.ScriptName -Leaf
        $line = $inv.ScriptLineNumber
        $fileInfo = "${file}:${line}"
    } else {
        $fileInfo = '<interactive>'
    }

    # Padding
    $levelPad = $normalizedLevel.PadRight(5)
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

function Get-FormattedLog {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Level,

        [string]$Filter, # Universal Wildcard (matches anywhere in the line)

        [switch]$Tail,

        [int]$Last = 0
    )

    $gcParams = @{ Path = $Path }
    
    if ($Tail) { 
        $gcParams.Wait = $true 
        if ($Last -gt 0) { 
            $gcParams.Tail = $Last 
        } else {
            $firstLine = $true
            $gcParams.Tail = 1
        }
    }

    Get-Content @gcParams | ForEach-Object {
        if ($firstLine) { 
            $firstLine = $false
            return 
        }

        # 1. Universal Filter: Check raw line first for performance
        if ($Filter -and $_ -notlike $Filter) { return }

        $parts = $_ -split '\|'
        if ($parts.Count -ge 5) {
            $obj = [PSCustomObject]@{
                Timestamp = $parts[0].Trim()
                Level     = $parts[1].Trim()
                Function  = $parts[2].Trim()
                Source    = $parts[3].Trim()
                Message   = ($parts[4..($parts.Count - 1)] -join '|').Trim()
            }

            # 2. Specific Level Filter (if provided)
            if (-not $Level -or ($obj.Level -ieq $Level)) {
                $obj
            }
        }
    }
}

