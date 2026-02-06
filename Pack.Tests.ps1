Describe "Complex Project Packer Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerComplexTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: Multi-Dependency Tree ---
        # ProjA -> [ProjB, ProjC]
        # ProjB -> [ProjD]
        # ProjC -> [ProjD]
        foreach ($p in 'A','B','C','D') { New-Item -Path "$MockRepo\Proj$p" -ItemType Directory | Out-Null }
        
        '@{ Version = "1.0.0"; Dependencies=@("../ProjB", "../ProjC") }' | Out-File "$MockRepo\ProjA\Manifest.psd1"
        '@{ Version = "1.0.0"; Dependencies=@("../ProjD") }'              | Out-File "$MockRepo\ProjB\Manifest.psd1"
        '@{ Version = "1.0.0"; Dependencies=@("../ProjD") }'              | Out-File "$MockRepo\ProjC\Manifest.psd1"
        '@{ Version = "1.0.0" }'                                            | Out-File "$MockRepo\ProjD\Manifest.psd1"

        # --- SETUP: Circular Dependency ---
        # ProjLoop1 -> ProjLoop2 -> ProjLoop1
        New-Item -Path "$MockRepo\ProjLoop1" -ItemType Directory | Out-Null
        New-Item -Path "$MockRepo\ProjLoop2" -ItemType Directory | Out-Null
        '@{ Version = "1.0.0"; Dependencies=@("../ProjLoop2") }' | Out-File "$MockRepo\ProjLoop1\Manifest.psd1"
        '@{ Version = "1.0.0"; Dependencies=@("../ProjLoop1") }' | Out-File "$MockRepo\ProjLoop2\Manifest.psd1"
    }

    It "Should correctly bundle multiple dependencies in one list" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -Destination $BuildDir
        
        $PathB = "$BuildDir\ProjA\Shared\ProjB"
        $PathC = "$BuildDir\ProjA\Shared\ProjC"
        $PathD_from_B = "$PathB\Shared\ProjD"
        $PathD_from_C = "$PathC\Shared\ProjD"

        Test-Path $PathB | Should -Be $true
        Test-Path $PathC | Should -Be $true
        Test-Path $PathD_from_B | Should -Be $true
        Test-Path $PathD_from_C | Should -Be $true
    }

    It "Should detect and block circular dependencies" {
        { 
            & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjLoop1" -Destination $BuildDir 
        } | Should -Throw -ExpectedMessage "*CIRCULAR DEPENDENCY DETECTED*"
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Packer Version Logging Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerVersionTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # Setup Dependency with specific version
        $DepA = New-Item -Path "$MockRepo\DepA" -ItemType Directory -Force
        '@{ Version = "2.5.4" }' | Out-File "$DepA\Manifest.psd1"

        # Setup Main Project
        $Main = New-Item -Path "$MockRepo\MainApp" -ItemType Directory -Force
        '@{ Version = "1.0.0"; Dependencies = @("../DepA") }' | Out-File "$Main\Manifest.psd1"
    }

    It "Should output the correct module versions during the fetch process" {
        $output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $Main -Destination $BuildDir
        
        $output | Should -Contain "[FETCH] MainApp (v1.0.0)"
        $output | Should -Contain "[FETCH] DepA (v2.5.4)"
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Packer Policy Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerPolicyTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force
    }

    It "Should throw an error if Version is missing" {
        $NoVer = New-Item -Path "$MockRepo\NoVer" -ItemType Directory -Force
        '@{ Dependencies = @() }' | Out-File "$NoVer\Manifest.psd1" # Missing Version

        { & "$PSScriptRoot\Pack.ps1" -ProjectPath $NoVer } | Should -Throw -ExpectedMessage "*VERSION REQUIRED*"
    }

    It "Should list all unique dependencies when -ListAvailable is used" {
        # Setup tree: A -> B -> C
        foreach($p in 'A','B','C') { 
            $folder = New-Item -Path "$MockRepo\Proj$p" -ItemType Directory -Force
            $ver = "1.0.$p"
            $req = if($p -eq 'A'){"@('../ProjB')"} elseif($p -eq 'B'){"@('../ProjC')"} else{"@()"}
            "@{ Version='$ver'; Dependencies=$req }" | Out-File "$folder\Manifest.psd1"
        }

        $output = & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -ListAvailable
        $output | Should -Contain "ProjA                v1.0.A"
        $output | Should -Contain "ProjB                v1.0.B"
        $output | Should -Contain "ProjC                v1.0.C"
    }
    
    It "Should preserve original manifests for both root and dependencies" {
        $Root = New-Item -Path "$MockRepo\RootPrj" -ItemType Directory -Force
        $Dep  = New-Item -Path "$MockRepo\DepPrj" -ItemType Directory -Force
        
        # FIX: Add Dependencies so the script actually recurses into DepPrj
        $ManifestContent = '@{ Version = "1.2.3"; Dependencies = @("../DepPrj"); CustomKey = "Preserved" }'
        $ManifestContent | Out-File "$Root\Manifest.psd1"
        '@{ Version = "1.0.0" }' | Out-File "$Dep\Manifest.psd1"
        
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Root -Destination $BuildDir
        
        # Verify Root
        $RootOutput = Import-PowerShellDataFile "$BuildDir\RootPrj\Manifest.psd1"
        $RootOutput.CustomKey | Should -Be "Preserved"
        
        # Verify Dependency (This will now be true because the script followed the link)
        Test-Path "$BuildDir\RootPrj\Shared\DepPrj\Manifest.psd1" | Should -Be $true
    }

    It "Should throw error if path exceeds the character limit" {
        $Root = New-Item -Path "$MockRepo\SomeProj" -ItemType Directory -Force
        
        # FIX: Add Dependencies so the script actually recurses into DepPrj
        $ManifestContent = '@{ Version = "1.0.0"; Dependencies = @("../DepPrj"); CustomKey = "Preserved" }'
        $ManifestContent | Out-File "$Root\Manifest.psd1"
        
        $LongPath = "C:\" + ("a" * 255)
        { 
            # We mock the destination to a long string
            & "$PSScriptRoot\Pack.ps1" -ProjectPath $Root -Dest $LongPath
        } | Should -Throw -ExpectedMessage "*PATH TOO LONG*"
    }

    AfterAll { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Packer Inventory (-ListAvailable) Tests" {
    BeforeAll {
        # Setup temporary workspace
        $TestRoot = New-Item -Path "$env:TEMP\PackerInventoryTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # Create a 3-level deep dependency tree:
        # App (v1.0.0) -> LibA (v2.1.0) -> LibB (v3.0.5)
        $App  = New-Item -Path "$MockRepo\App" -ItemType Directory -Force
        $LibA = New-Item -Path "$MockRepo\LibA" -ItemType Directory -Force
        $LibB = New-Item -Path "$MockRepo\LibB" -ItemType Directory -Force

        # Manifests
        '@{ Version="1.0.0"; Dependencies=@("../LibA") }' | Out-File "$App\Manifest.psd1"
        '@{ Version="2.1.0"; Dependencies=@("../LibB") }' | Out-File "$LibA\Manifest.psd1"
        '@{ Version="3.0.5"; Dependencies=@() }'           | Out-File "$LibB\Manifest.psd1"
        
        # Dummy script files
        'Write-Host "App"'  | Out-File "$App\App.ps1"
        'Write-Host "LibA"' | Out-File "$LibA\LibA.ps1"
    }

    Context "Dependency Discovery" {
        It "Should list all unique modules and their versions in the console output" {
            # Execute with ListAvailable switch
            $Output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir -ListAvailable

            # Verify the discovery header and each module version
            $Output -join "`n" | Should -Match "--- Dependency Inventory ---"
            $Output -join "`n" | Should -Match "App\s+v1\.0\.0"
            $Output -join "`n" | Should -Match "LibA\s+v2\.1\.0"
            $Output -join "`n" | Should -Match "LibB\s+v3\.0\.5"
        }

        It "Should NOT create any folders or copy files during a ListAvailable run" {
            # Ensure the Build directory remains empty
            $BuildFiles = Get-ChildItem -Path $BuildDir
            $BuildFiles.Count | Should -Be 0
            
            $AppPath = Join-Path $BuildDir "App"
            Test-Path $AppPath | Should -Be $false
        }
    }

    Context "Error Handling" {
        It "Should still enforce version requirements even in ListAvailable mode" {
            $Broken = New-Item -Path "$MockRepo\Broken" -ItemType Directory -Force
            '@{ Dependencies=@() }' | Out-File "$Broken\Manifest.psd1" # Missing Version

            { 
                & "$PSScriptRoot\Pack.ps1" -ProjectPath $Broken -ListAvailable 
            } | Should -Throw -ExpectedMessage "*VERSION REQUIRED*"
        }
    }
    
    It "Should NOT generate a manifest during -ListAvailable" {
        $Output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir -ListAvailable

        $ManifestPath = "$BuildDir\App\Manifest.psd1"
        Test-Path $ManifestPath | Should -Be $false
    }

    AfterAll {
        # Cleanup
        if (Test-Path $TestRoot) { 
            Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue 
        }
    }
}

Describe "Packer Cleanup and Filtering Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerFilterTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # Create a standard project
        $Project = New-Item -Path "$MockRepo\FilterProj" -ItemType Directory -Force
        '@{ Version = "1.0.0" }' | Out-File "$Project\Manifest.psd1"
        'Write-Host "Keep me"' | Out-File "$Project\Main.ps1"
        
        # Create folders that SHOULD BE IGNORED
        New-Item -Path "$Project\.git" -ItemType Directory | Out-Null
        'secret' | Out-File "$Project\.git\config"
        
        New-Item -Path "$Project\Build" -ItemType Directory | Out-Null
        'old-build' | Out-File "$Project\Build\old.txt"
        
        New-Item -Path "$Project\Shared" -ItemType Directory | Out-Null
        'dependency-artifact' | Out-File "$Project\Shared\old-dep.txt"
    }

    It "Should wipe the destination directory before starting a new build" {
        # 1. Create a "Ghost File" in the build directory that isn't in the source
        $GhostFile = Join-Path $BuildDir "FilterProj\ghost.txt"
        New-Item -Path $GhostFile -ItemType File -Value "I should be deleted" -Force | Out-Null
        
        # 2. Run the packer
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Project -Destination $BuildDir
        
        # 3. Verify the ghost file is gone
        Test-Path $GhostFile | Should -Be $false
        Test-Path "$BuildDir\FilterProj\Main.ps1" | Should -Be $true
    }

    It "Should exclude .git, Build, and Shared folders from the final package" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Project -Destination $BuildDir
        $DestRoot = "$BuildDir\FilterProj"

        # Verify main files exist
        Test-Path "$DestRoot\Main.ps1" | Should -Be $true
        
        # Verify ignored patterns do NOT exist
        Test-Path "$DestRoot\.git" | Should -Be $false
        Test-Path "$DestRoot\Build" | Should -Be $false
        
        # Note: The 'Shared' folder should only exist if created by the dependency logic,
        # but the source's own 'Shared' folder (and its content) should be excluded.
        Test-Path "$DestRoot\Shared\old-dep.txt" | Should -Be $false
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
