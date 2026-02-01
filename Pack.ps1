param(
    [Parameter(Mandatory)] [string]$ProjectPath,
    [string]$Destination = "$PSScriptRoot\Build",
    [int]$Limit = 260
)

$script:ProcessingStack = New-Object System.Collections.Generic.Stack[string]

function Invoke-RecursivePack {
    param([string]$Src, [string]$Dest)

    $normalizedSrc = (Resolve-Path $Src).Path
    
    if ($script:ProcessingStack.Contains($normalizedSrc)) {
        $chain = ($script:ProcessingStack.ToArray() | ForEach-Object { Split-Path $_ -Leaf }) -join " -> "
        throw "CIRCULAR DEPENDENCY DETECTED: $chain -> $(Split-Path $normalizedSrc -Leaf)"
    }
    $script:ProcessingStack.Push($normalizedSrc)

    try {
        if ($Dest.Length -ge $Limit) { throw "Path too long: $Dest" }

        if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null

        # Resolve Manifest early to get Version for logging
        $srcPsd1 = Get-ChildItem -Path $Src -Filter "*.psd1" | Select-Object -First 1
        $version = "unknown"
        if ($srcPsd1) {
            $manifestData = Import-PowerShellDataFile -Path $srcPsd1.FullName
            if ($manifestData.ModuleVersion) { $version = $manifestData.ModuleVersion }
        }

        Write-Output "[FETCH] $(Split-Path $Src -Leaf) (v$version)"

        Copy-Item -Path "$Src\*" -Destination $Dest -Recurse -Exclude "Build", "Shared", ".git"

        if ($manifestData -and $manifestData.RequiredModules) {
            $sharedDir = New-Item -ItemType Directory -Path (Join-Path $Dest "Shared") -Force
            
            foreach ($relPath in $manifestData.RequiredModules) {
                $depSrc = Resolve-Path (Join-Path $Src $relPath) -ErrorAction Stop
                $depDest = Join-Path $sharedDir (Split-Path $depSrc -Leaf)
                Invoke-RecursivePack -Src $depSrc.Path -Dest $depDest
            }
        }
    }
    finally {
        $null = $script:ProcessingStack.Pop()
    }
}

$ProjectName = Split-Path $ProjectPath -Leaf
$FinalDest = Join-Path $Destination $ProjectName
Write-Output "--- Starting Build: $ProjectName ---"
Invoke-RecursivePack -Src $ProjectPath -Dest $FinalDest
Write-Output "--- Build Complete ---"
