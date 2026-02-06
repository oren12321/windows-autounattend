param(
    [Parameter(Mandatory)] [string]$ProjectPath,
    [string]$Destination = "$PSScriptRoot\Build",
    [int]$Limit = 260,
    [switch]$ListAvailable
)

$script:ProcessingStack = New-Object System.Collections.Generic.Stack[string]
$script:DiscoveredModules = @{}

function Invoke-RecursivePack {
    param([string]$Src, [string]$Dest, [switch]$AuditOnly, [switch]$IsRoot)
    
    $normalizedSrc = (Resolve-Path $Src).Path
    $folderName = Split-Path $normalizedSrc -Leaf
    
    # Initialize Root Scope for security check
    if ($IsRoot) { $script:RootPath = $normalizedSrc }
    
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
        if (-not $manifestData.Version) { throw "VERSION REQUIRED: .psd1 for '$folderName' must define a 'Version'." }

        if (-not $script:DiscoveredModules.ContainsKey($folderName)) {
            $script:DiscoveredModules[$folderName] = $manifestData.Version
        }

        # 3. File Copy (Project Files)
        if (-not $AuditOnly) {
            if ($Dest.Length -ge $Limit) { throw "PATH TOO LONG: Cannot pack to '$Dest' (Length: $($Dest.Length))" }
            Write-Output "[FETCH] $folderName (v$($manifestData.Version))"
            if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
            
            # Copy only local project files (excludes Shared/Build/.git)
            Get-ChildItem -Path $Src | Where-Object {
                $_.Name -notmatch "^(Shared|Build|\.git)$"
            } | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $Dest -Recurse -Force
            }
        }

        # 4. Handle INTERNAL SubProjects (Orchestration)
        # These do NOT create a 'Shared' folder at this level.
        if ($manifestData.SubProjects) {
            foreach ($subManiPath in $manifestData.SubProjects) {
                $subManiFullPath = [System.IO.Path]::GetFullPath((Join-Path $Src $subManiPath))
                if (-not (Test-Path $subManiFullPath)) { throw "INTERNAL MANIFEST NOT FOUND: $subManiPath" }
                
                # SCOPE GUARD: Ensure internal sub-projects are inside the Root Project tree
                if (-not $subManiFullPath.StartsWith($script:RootPath)) {
                    throw "SECURITY VIOLATION: SubProject '$subManiFullPath' is outside the root project tree."
                }
                
                $subDestDir = if (-not $AuditOnly) { Join-Path $Dest $subManiPath } else { "" }

                Invoke-RecursivePack -Src $subManiFullPath -Dest $subDestDir -AuditOnly:$AuditOnly
            }
        }

        # 5. Handle EXTERNAL Dependencies (Vendor-Inlining)
        # These DO create a 'Shared' folder and a 'Paths.ps1' at this level.
        if ($manifestData.Dependencies) {
            $mapEntries = @()
            foreach ($relPath in $manifestData.Dependencies) {
                $depSrcPath = [System.IO.Path]::GetFullPath((Join-Path $Src $relPath))
                if (-not (Test-Path $depSrcPath)) { throw "DEPENDENCY NOT FOUND: '$folderName' requires '$relPath' at '$depSrcPath'" }
                
                $depName = Split-Path $depSrcPath -Leaf
                $depDest = $null
                
                if (-not $AuditOnly) {
                    $depDest = Join-Path $Dest "Shared" | Join-Path -ChildPath $depName
                    $mapEntries += "$depName = `"`$PSScriptRoot\Shared\$depName`""
                }
                
                # Check if dependency is a project or a static asset
                if (Test-Path (Join-Path $depSrcPath "Manifest.psd1")) {
                    Invoke-RecursivePack -Src $depSrcPath -Dest $depDest -AuditOnly:$AuditOnly
                } elseif (-not $AuditOnly) {
                    if (-not (Test-Path (Split-Path $depDest))) { New-Item -ItemType Directory -Path (Split-Path $depDest) -Force | Out-Null }
                    Copy-Item -Path $depSrcPath -Destination $depDest -Recurse -Force
                }
            }

            if (-not $AuditOnly -and $mapEntries.Count -gt 0) {
                $mapContent = "`$Paths = @{`r`n    " + ($mapEntries -join ";`r`n    ") + "`r`n}"
                $mapContent | Out-File (Join-Path $Dest "Paths.ps1") -Force -Encoding UTF8
            }
        }
    }
    finally { $null = $script:ProcessingStack.Pop() }
}

# --- Execution Logic (Clean and Run) ---
if ($ListAvailable) {
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly
    Write-Output "--- Dependency Inventory ---"
    $script:DiscoveredModules.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Output "$($_.Key.PadRight(20)) v$($_.Value)"
    }
} else {
    Write-Output "[VALIDATE] Checking project tree..."
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly
    
    if (Test-Path $Destination) {
        Write-Output "[CLEAN] Preparing destination..."
        Remove-Item "$Destination\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Output "--- Starting Build: $(Split-Path $ProjectPath -Leaf) ---"
    Invoke-RecursivePack -Src $ProjectPath -Dest (Join-Path $Destination (Split-Path $ProjectPath -Leaf))
    Write-Output "--- Build Complete ---"
}
