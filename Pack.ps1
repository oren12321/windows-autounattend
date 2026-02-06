param(
    [Parameter(Mandatory)] [string]$ProjectPath,
    [string]$Destination = "$PSScriptRoot\Build",
    [int]$Limit = 260,
    [switch]$ListAvailable
)

$script:ProcessingStack = New-Object System.Collections.Generic.Stack[string]
$script:DiscoveredModules = @{} # Track unique modules for -ListAvailable

function Invoke-RecursivePack {
    param([string]$Src, [string]$Dest, [switch]$AuditOnly)
    
    $normalizedSrc = (Resolve-Path $Src).Path
    $folderName = Split-Path $normalizedSrc -Leaf
    
    # 1. Circularity Check
    if ($script:ProcessingStack.Contains($normalizedSrc)) {
        $chain = ($script:ProcessingStack.ToArray() | ForEach-Object { Split-Path $_ -Leaf }) -join " -> "
        throw "CIRCULAR DEPENDENCY DETECTED: $chain -> $folderName"
    }
    $script:ProcessingStack.Push($normalizedSrc)

    try {
        # 2. Manifest Validation
        $srcPsd1 = Get-ChildItem -Path $normalizedSrc -Filter "Manifest.psd1" | Select-Object -First 1
        if (-not $srcPsd1) { throw "MISSING MANIFEST: Project '$folderName' must have a .psd1 file." }
        
        $manifestData = Import-PowerShellDataFile -Path $srcPsd1.FullName
        if (-not $manifestData.Version) { 
            throw "VERSION REQUIRED: .psd1 for '$folderName' must define a 'Version'." 
        }

        # 3. Track for ListAvailable
        if (-not $script:DiscoveredModules.ContainsKey($folderName)) {
            $script:DiscoveredModules[$folderName] = $manifestData.Version
        }

        if (-not $AuditOnly) {
            if ($Dest.Length -ge $Limit) { throw "PATH TOO LONG: Cannot pack to '$Dest' (Length: $($Dest.Length))" }
            
            if ($Dest.Length -ge $Limit) { throw "Path too long: $Dest" }
            Write-Output "[FETCH] $folderName (v$($manifestData.Version))"
            
            if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
            New-Item -ItemType Directory -Path $Dest -Force | Out-Null
            
            Get-ChildItem -Path $Src -Recurse | Where-Object {
                # This checks if the folder's path starts with the specific path you want to ignore
                $_.FullName -notlike "$Src\Shared*" -and 
                $_.FullName -notlike "$Src\Build*" -and 
                $_.FullName -notlike "$Src\.git*"
            } | Copy-Item -Destination { Join-Path $Dest $_.FullName.Substring($Src.Length) } -Force
        }

        # 4. Recurse
        if ($manifestData.Dependencies) {
            foreach ($relPath in $manifestData.Dependencies) {
                $depSrc = Resolve-Path (Join-Path $Src $relPath) -ErrorAction Stop
                if (-not $AuditOnly) {
                    $depDest = Join-Path $Dest "Shared" | Join-Path -ChildPath (Split-Path $depSrc -Leaf)
                }
                
                $invokeParams = @{
                    Src  = $depSrc.Path
                    Dest = $depDest
                }

                if ($AuditOnly) {
                    $invokeParams.AuditOnly = $true
                }

                Invoke-RecursivePack @invokeParams
            }
        }
    }
    finally { $null = $script:ProcessingStack.Pop() }
}

# Execution Logic
if ($ListAvailable) {
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly
    Write-Output "--- Dependency Inventory ---"
    $script:DiscoveredModules.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object {
            Write-Output "$($_.Key.PadRight(20)) v$($_.Value)"
        }
} else {
    Write-Output "--- Starting Build: $(Split-Path $ProjectPath -Leaf) ---"
    Invoke-RecursivePack -Src $ProjectPath -Dest (Join-Path $Destination (Split-Path $ProjectPath -Leaf))
    Write-Output "--- Build Complete ---"
}
