param(
    [Parameter(Mandatory)] [string]$ProjectPath,
    [string]$Destination = "$PSScriptRoot\Build",
    [int]$Limit = 260,
    [switch]$ListAvailable
)

$script:ProcessingStack = New-Object System.Collections.Generic.Stack[string]
$script:DiscoveredModules = @{}

function Invoke-RecursivePack {
    param([string]$Src, [string]$Dest, [switch]$AuditOnly)
    
    $normalizedSrc = (Resolve-Path $Src).Path
    $folderName = Split-Path $normalizedSrc -Leaf
    
    if ($script:ProcessingStack.Contains($normalizedSrc)) {
        $chain = ($script:ProcessingStack.ToArray() | ForEach-Object { Split-Path $_ -Leaf }) -join " -> "
        throw "CIRCULAR DEPENDENCY DETECTED: $chain -> $folderName"
    }
    $script:ProcessingStack.Push($normalizedSrc)

    try {
        $srcPsd1 = Get-ChildItem -Path $normalizedSrc -Filter "Manifest.psd1" | Select-Object -First 1
        if (-not $srcPsd1) { throw "MISSING MANIFEST: Project '$folderName' must have a .psd1 file." }
        
        $manifestData = Import-PowerShellDataFile -Path $srcPsd1.FullName
        if (-not $manifestData.Version) { throw "VERSION REQUIRED: .psd1 for '$folderName' must define a 'Version'." }

        if (-not $script:DiscoveredModules.ContainsKey($folderName)) {
            $script:DiscoveredModules[$folderName] = $manifestData.Version
        }
        
        if ($manifestData.Dependencies) {
            foreach ($relPath in $manifestData.Dependencies) {
                $depSrcPath = [System.IO.Path]::GetFullPath((Join-Path $Src $relPath))
                if (-not (Test-Path $depSrcPath)) { 
                    throw "DEPENDENCY NOT FOUND: Project '$folderName' requires '$relPath', but it was not found at '$depSrcPath'" 
                }
            }
        }

        if (-not $AuditOnly) {
            if ($Dest.Length -ge $Limit) { throw "PATH TOO LONG: Cannot pack to '$Dest' (Length: $($Dest.Length))" }
            Write-Output "[FETCH] $folderName (v$($manifestData.Version))"
            if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
            
            Get-ChildItem -Path $Src -Recurse | Where-Object {
                $_.FullName -notmatch "\\(Shared|Build|\.git)($|\\)"
            } | ForEach-Object {
                $relPath = $_.FullName.Substring($Src.Length).TrimStart('\')
                if ($relPath -ne "") {
                    $targetPath = Join-Path $Dest $relPath
                    if ($_.PSIsContainer) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }
                    else { Copy-Item -Path $_.FullName -Destination $targetPath -Force }
                }
            }
        }

        if ($manifestData.Dependencies) {
            $mapEntries = @()
            foreach ($relPath in $manifestData.Dependencies) {
                # Ensure we resolve the path relative to the current source
                $depSrcPath = [System.IO.Path]::GetFullPath((Join-Path $Src $relPath))
                if (-not (Test-Path $depSrcPath)) { throw "DEPENDENCY NOT FOUND: $relPath at $depSrcPath" }
                
                $depName = Split-Path $depSrcPath -Leaf
                $depDest = $null
                
                if (-not $AuditOnly) {
                    $depDest = Join-Path $Dest "Shared" | Join-Path -ChildPath $depName
                    # We store the entry for the Paths.ps1
                    $mapEntries += "$depName = `"`$PSScriptRoot\Shared\$depName`""
                }
                
                Invoke-RecursivePack -Src $depSrcPath -Dest $depDest -AuditOnly:$AuditOnly
            }

            # Write the Paths.ps1 file if we are in build mode and have dependencies
            if (-not $AuditOnly -and $mapEntries.Count -gt 0) {
                $mapContent = "`$Paths = @{`r`n    " + ($mapEntries -join ";`r`n    ") + "`r`n}"
                $mapContent | Out-File (Join-Path $Dest "Paths.ps1") -Force -Encoding UTF8
            }
        }
    }
    finally { $null = $script:ProcessingStack.Pop() }
}

# --- Execution Logic ---
if ($ListAvailable) {
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly
    Write-Output "--- Dependency Inventory ---"
    $script:DiscoveredModules.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Output "$($_.Key.PadRight(20)) v$($_.Value)"
    }
} else {
    Write-Output "[VALIDATE] Checking dependency tree..."
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly
    
    # Initial Clean: Only wipe the build directory once at the start of a build
    if (Test-Path $Destination) {
        Write-Output "[CLEAN] Preparing destination..."
        Remove-Item "$Destination\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Output "--- Starting Build: $(Split-Path $ProjectPath -Leaf) ---"
    $rootDest = Join-Path $Destination (Split-Path $ProjectPath -Leaf)
    Invoke-RecursivePack -Src $ProjectPath -Dest $rootDest
    Write-Output "--- Build Complete ---"
}
