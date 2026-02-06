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
            if ($Dest.Length -ge $Limit) { throw "PATH TOO LONG: $Dest" }
            
            # ALWAYS ensure the directory exists so Shared/Paths.ps1 have a home
            if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }

            # ONLY copy files if it's the root OR if the destination is empty
            # This prevents the "Redundant Copy" while ensuring the files exist
            $filesExist = Get-ChildItem -Path $Dest -Force | Select-Object -First 1
            if ($IsRoot -or -not $filesExist) {
                Write-Output "[FETCH] $folderName (v$($manifestData.Version))"
                Get-ChildItem -Path $Src | Where-Object {
                    $_.Name -notmatch "^(Shared|Build|\.git)$"
                } | ForEach-Object {
                    Copy-Item -Path $_.FullName -Destination $Dest -Recurse -Force
                }
            }
        }

        # 4. Handle INTERNAL SubProjects
        $localNames = @{} # Track all names used in this specific manifest
        if ($manifestData.SubProjects) {
            foreach ($subRelPath in $manifestData.SubProjects) {
                $subSrcDir = [System.IO.Path]::GetFullPath((Join-Path $Src $subRelPath))
                if (-not $subSrcDir.StartsWith($script:RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "SECURITY VIOLATION: SubProject '$subRelPath' is outside the root tree."
                }
                if (-not (Test-Path $subSrcDir)) { throw "SUBPROJECT NOT FOUND: $subRelPath" }

                $subName = Split-Path $subSrcDir -Leaf
                $localNames[$subName] = "SubProject"

                $subDestDir = if (-not $AuditOnly) { Join-Path $Dest $subRelPath } else { "" }
                Invoke-RecursivePack -Src $subSrcDir -Dest $subDestDir -AuditOnly:$AuditOnly -IsRoot:$false
            }
        }

        # 5. Handle EXTERNAL Dependencies
        if ($manifestData.Dependencies) {
            $mapEntries = @()
            foreach ($relPath in $manifestData.Dependencies) {
                $depSrcPath = [System.IO.Path]::GetFullPath((Join-Path $Src $relPath))
                if (-not (Test-Path $depSrcPath)) { throw "DEPENDENCY NOT FOUND: '$folderName' requires '$relPath'" }
                
                $depName = Split-Path $depSrcPath -Leaf

                # --- IMPROVED COLLISION DETECTION ---
                # 1. Check against reserved build artifact names
                if ($depName -eq "Shared" -or $depName -eq "Paths") {
                    throw "NAMING COLLISION: The name '$depName' is reserved for build artifacts in project '$folderName'."
                }

                # 2. Check against internal names (SubProjects or other Dependencies)
                if ($localNames.ContainsKey($depName)) {
                    $conflictType = $localNames[$depName]
                    throw "NAMING COLLISION: '$depName' is defined as both a $conflictType and a Dependency in project '$folderName'."
                }
                $localNames[$depName] = "Dependency"

                $depDest = if (-not $AuditOnly) { Join-Path $Dest "Shared" | Join-Path -ChildPath $depName } else { $null }
                
                $isLeaf = Test-Path $depSrcPath -PathType Leaf
                if (-not $AuditOnly) { 
                    $pathValue = if ($isLeaf) { "`$PSScriptRoot\Shared\$depName\$depName" } else { "`$PSScriptRoot\Shared\$depName" }
                    $mapEntries += "'$depName' = `"$pathValue`"" 
                }
                
                $isProject = (-not $isLeaf) -and (Test-Path (Join-Path $depSrcPath "Manifest.psd1"))
                
                if ($isProject) {
                    Invoke-RecursivePack -Src $depSrcPath -Dest $depDest -AuditOnly:$AuditOnly
                } elseif (-not $AuditOnly) {
                    if ($isLeaf) {
                        New-Item -ItemType Directory -Path $depDest -Force | Out-Null
                        Copy-Item -Path $depSrcPath -Destination $depDest -Force
                    } else {
                        Copy-Item -Path $depSrcPath -Destination (Split-Path $depDest -Parent) -Recurse -Force
                    }
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
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly -IsRoot
    Write-Output "--- Dependency Inventory ---"
    $script:DiscoveredModules.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Output "$($_.Key.PadRight(20)) v$($_.Value)"
    }
} else {
    Write-Output "[VALIDATE] Checking project tree..."
    Invoke-RecursivePack -Src $ProjectPath -Dest "" -AuditOnly -IsRoot
    
    if (Test-Path $Destination) {
        Write-Output "[CLEAN] Preparing destination..."
        Remove-Item "$Destination\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Output "--- Starting Build: $(Split-Path $ProjectPath -Leaf) ---"
    Invoke-RecursivePack -Src $ProjectPath -Dest (Join-Path $Destination (Split-Path $ProjectPath -Leaf)) -IsRoot
    Write-Output "--- Build Complete ---"
}
