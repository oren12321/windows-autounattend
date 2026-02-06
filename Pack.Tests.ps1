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
    
    It "Should generate a Paths.ps1 file mapping dependencies" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -Destination $BuildDir
        $PathFile = "$BuildDir\ProjA\Paths.ps1"
        
        Test-Path $PathFile | Should -Be $true
        
        # Load the generated file and check the variable
        . $PathFile
        $Paths.ProjB | Should -Match "Shared\\ProjB"
        $Paths.ProjC | Should -Match "Shared\\ProjC"
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
    
    It "Should preserve original SubProjects for both root and dependencies" {
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
    
    It "Should throw an error and NOT clean the destination if a dependency is missing" {
        $Root = New-Item -Path "$MockRepo\MissingDepProj" -ItemType Directory -Force
        '@{ Version = "1.0.0"; Dependencies = @("../NonExistent") }' | Out-File "$Root\Manifest.psd1"
        
        # Create a file in Build to prove it wasn't cleaned
        $Ghost = Join-Path $BuildDir "should-stay.txt"
        "test" | Out-File $Ghost -Force

        { & "$PSScriptRoot\Pack.ps1" -ProjectPath $Root -Destination $BuildDir } | Should -Throw -ExpectedMessage "*DEPENDENCY NOT FOUND*"
        
        # Verification
        Test-Path $Ghost | Should -Be $true
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

        # SubProjects
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

Describe "Composite Project Orchestration Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerCompositeTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP EXTERNAL LIBS ---
        $LibNet = New-Item -Path "$MockRepo\External\NetworkLib" -ItemType Directory -Force
        '@{ Version = "2.0.0" }' | Out-File "$LibNet\Manifest.psd1"

        $LibLog = New-Item -Path "$MockRepo\External\LoggerLib" -ItemType Directory -Force
        '@{ Version = "1.5.0" }' | Out-File "$LibLog\Manifest.psd1"

        # --- SETUP COMPOSITE APP ---
        $AppRoot = New-Item -Path "$MockRepo\MainApp" -ItemType Directory -Force
        $CoreDir = New-Item -Path "$AppRoot\src\Core" -ItemType Directory -Force
        $ApiDir  = New-Item -Path "$AppRoot\src\Api"  -ItemType Directory -Force

        # Root Manifest: Orchestrates two internal sub-projects
        '@{ 
            Version = "1.0.0"; 
            SubProjects = @("src/Core", "src/Api") 
        }' | Out-File "$AppRoot\Manifest.psd1"

        # Core Manifest: Has its own external dependency (Logger)
        '@{ 
            Version = "1.1.0"; 
            Dependencies = @("../../../External/LoggerLib") 
        }' | Out-File "$CoreDir\Manifest.psd1"

        # API Manifest: Has its own external dependency (Network)
        '@{ 
            Version = "1.2.0"; 
            Dependencies = @("../../../External/NetworkLib") 
        }' | Out-File "$ApiDir\Manifest.psd1"
    }

    It "Should correctly build the composite tree with localized Paths.ps1 files" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        
        $BuildRoot = "$BuildDir\MainApp"

        # 1. Verify Structure Preservation
        Test-Path "$BuildRoot\src\Core\Manifest.psd1" | Should -Be $true
        Test-Path "$BuildRoot\src\Api\Manifest.psd1"  | Should -Be $true

        # 2. Verify Localized Dependencies (Encapsulation)
        # Core should have Logger in its own Shared folder
        Test-Path "$BuildRoot\src\Core\Shared\LoggerLib" | Should -Be $true
        Test-Path "$BuildRoot\src\Core\Paths.ps1"        | Should -Be $true

        # Api should have Network in its own Shared folder
        Test-Path "$BuildRoot\src\Api\Shared\NetworkLib" | Should -Be $true
        Test-Path "$BuildRoot\src\Api\Paths.ps1"        | Should -Be $true

        # 3. Verify Root does NOT have a Paths.ps1 (it had no direct dependencies)
        Test-Path "$BuildRoot\Paths.ps1" | Should -Be $false
    }

    It "Should verify that Paths.ps1 content points to the correct local Shared folder" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        
        # Dot-source the Core Paths file
        $CorePathsFile = "$BuildDir\MainApp\src\Core\Paths.ps1"
        . $CorePathsFile

        # The $Paths variable should contain LoggerLib
        $Paths.ContainsKey("LoggerLib") | Should -Be $true
        $Paths.LoggerLib | Should -Match "src\\Core\\Shared\\LoggerLib"
    }

    It "Should list all composite versions in -ListAvailable" {
        $output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -ListAvailable
        
        $output | Should -Contain "MainApp              v1.0.0"
        $output | Should -Contain "Core                 v1.1.0"
        $output | Should -Contain "Api                  v1.2.0"
        $output | Should -Contain "LoggerLib            v1.5.0"
        $output | Should -Contain "NetworkLib           v2.0.0"
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Packer Stress Test - Supported Features Only" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\SpiderwebTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- EXTERNAL REPO (Shared Libraries) ---
        $ExtLibA = New-Item -Path "$MockRepo\External\LibA" -ItemType Directory -Force
        '@{ Version = "1.0.0" }' | Out-File "$ExtLibA\Manifest.psd1"
        
        $ExtLibB = New-Item -Path "$MockRepo\External\LibB" -ItemType Directory -Force
        '@{ Version = "2.2.0"; Dependencies = @("../../External/LibA") }' | Out-File "$ExtLibB\Manifest.psd1"

        # --- COMPOSITE APP REPO ---
        # Structure:
        # MegaApp
        #  ├── src/Core (Orchestrates Storage) -> Depends on LibA
        #  │    └── src/Core/Storage (Leaf) -> Depends on LibB
        #  └── src/Plugins (Leaf) -> Depends on LibA
        
        $AppRoot    = New-Item -Path "$MockRepo\MegaApp" -ItemType Directory -Force
        $CoreDir    = New-Item -Path "$AppRoot\src\Core" -ItemType Directory -Force
        $StorageDir = New-Item -Path "$CoreDir\src\Storage" -ItemType Directory -Force
        $PluginDir  = New-Item -Path "$AppRoot\src\Plugins" -ItemType Directory -Force

        # 1. MegaApp (Root)
        '@{ Version="1.0"; SubProjects=@("src/Core", "src/Plugins") }' | Out-File "$AppRoot\Manifest.psd1"

        # 2. Core (Sub-project)
        '@{ 
            Version = "1.1"; 
            SubProjects = @("src/Storage"); 
            Dependencies = @("../../../External/LibA") 
        }' | Out-File "$CoreDir\Manifest.psd1"

        # 3. Storage (Deeply Nested Sub-project)
        '@{ 
            Version = "1.1.1"; 
            Dependencies = @("../../../../../External/LibB") 
        }' | Out-File "$StorageDir\Manifest.psd1"

        # 4. Plugins (Side-branch)
        '@{ 
            Version = "1.0.0"; 
            Dependencies = @("../../../External/LibA") 
        }' | Out-File "$PluginDir\Manifest.psd1"
    }

    It "Should successfully validate the entire recursive tree" {
        { & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir -ListAvailable } | Should -Not -Throw
    }

    It "Should isolate LibA in separate 'Shared' folders for both Core and Plugins" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        $Base = "$BuildDir\MegaApp"

        # Verify Core's LibA
        Test-Path "$Base\src\Core\Shared\LibA\Manifest.psd1" | Should -Be $true
        Test-Path "$Base\src\Core\Paths.ps1" | Should -Be $true

        # Verify Plugins' LibA
        Test-Path "$Base\src\Plugins\Shared\LibA\Manifest.psd1" | Should -Be $true
        Test-Path "$Base\src\Plugins\Paths.ps1" | Should -Be $true
    }

    It "Should handle deep dependency chains (Storage -> LibB -> LibA)" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        
        $StorageShared = "$BuildDir\MegaApp\src\Core\src\Storage\Shared"
        
        # Verify LibB is in Storage's shared folder
        Test-Path "$StorageShared\LibB\Manifest.psd1" | Should -Be $true
        
        # Verify LibB's own dependency (LibA) is nested inside LibB's shared folder
        Test-Path "$StorageShared\LibB\Shared\LibA\Manifest.psd1" | Should -Be $true
    }

    It "Should ensure Paths.ps1 files only contain the immediate dependencies" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        
        # Load Core's Paths
        . "$BuildDir\MegaApp\src\Core\Paths.ps1"
        $Paths.ContainsKey("LibA") | Should -Be $true
        $Paths.ContainsKey("LibB") | Should -Be $false # LibB belongs to Storage, not Core
    }

    It "Should inventory all 6 projects with correct versions" {
        $output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -ListAvailable
        
        $output | Should -Contain "MegaApp              v1.0"
        $output | Should -Contain "Core                 v1.1"
        $output | Should -Contain "Storage              v1.1.1"
        $output | Should -Contain "Plugins              v1.0.0"
        $output | Should -Contain "LibB                 v2.2.0"
        $output | Should -Contain "LibA                 v1.0.0"
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Project Tree Integrity Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\TreeIntegrityTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: A Complex Internal Structure ---
        # MainApp
        #  ├── docs/readme.txt
        #  ├── src/Core/ (SubProject)
        #  │    ├── scripts/init.ps1
        #  │    └── src/Core/Storage/ (SubProject)
        #  │         └── data/schema.sql
        #  └── assets/logo.png

        $AppRoot = New-Item -Path "$MockRepo\MainApp" -ItemType Directory -Force
        
        # Files at root
        New-Item -Path "$AppRoot\docs" -ItemType Directory | Out-Null
        'documentation' | Out-File "$AppRoot\docs\readme.txt"
        
        New-Item -Path "$AppRoot\assets" -ItemType Directory | Out-Null
        'binary-data' | Out-File "$AppRoot\assets\logo.png"

        # Core SubProject
        $CoreDir = New-Item -Path "$AppRoot\src\Core" -ItemType Directory -Force
        New-Item -Path "$CoreDir\scripts" -ItemType Directory | Out-Null
        'init-script' | Out-File "$CoreDir\scripts\init.ps1"

        # Storage Nested SubProject
        $StorageDir = New-Item -Path "$CoreDir\src\Storage" -ItemType Directory -Force
        New-Item -Path "$StorageDir\data" -ItemType Directory | Out-Null
        'sql-schema' | Out-File "$StorageDir\data\schema.sql"

        # --- MANIFESTS ---
        '@{ Version="1.0"; SubProjects=@("src/Core") }' | Out-File "$AppRoot\Manifest.psd1"
        '@{ Version="1.1"; SubProjects=@("src/Storage") }' | Out-File "$CoreDir\Manifest.psd1"
        '@{ Version="1.2" }' | Out-File "$StorageDir\Manifest.psd1"
    }

    It "Should mirror the entire source tree structure exactly in the build folder" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        $BuildRoot = "$BuildDir\MainApp"

        # 1. Verify Root level files/folders (Non-manifest items)
        Test-Path "$BuildRoot\docs\readme.txt" | Should -Be $true
        Test-Path "$BuildRoot\assets\logo.png" | Should -Be $true

        # 2. Verify Level 1 SubProject contents
        Test-Path "$BuildRoot\src\Core\scripts\init.ps1" | Should -Be $true
        
        # 3. Verify Level 2 (Nested) SubProject contents
        Test-Path "$BuildRoot\src\Core\src\Storage\data\schema.sql" | Should -Be $true
    }

    It "Should ensure file content was preserved during the copy" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $AppRoot -Destination $BuildDir
        
        $SchemaPath = "$BuildDir\MainApp\src\Core\src\Storage\data\schema.sql"
        Get-Content $SchemaPath | Should -Be "sql-schema"
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Project Exclusion Policy Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\ExclusionPolicyTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: A project containing forbidden folders ---
        $Project = New-Item -Path "$MockRepo\DirtyProj" -ItemType Directory -Force
        '@{ Version = "1.0.0" }' | Out-File "$Project\Manifest.psd1"
        
        # 1. Create .git folder and content
        $GitDir = New-Item -Path "$Project\.git" -ItemType Directory -Force
        'git-internal-data' | Out-File "$GitDir\config"

        # 2. Create Build folder and content
        $OldBuildDir = New-Item -Path "$Project\Build" -ItemType Directory -Force
        'stale-artifact' | Out-File "$OldBuildDir\old_build.log"

        # 3. Create Shared folder (should be ignored from source)
        $OldSharedDir = New-Item -Path "$Project\Shared" -ItemType Directory -Force
        'old-dependency' | Out-File "$OldSharedDir\lib.dll"

        # 4. Create a valid nested folder to ensure normal recursion works
        $ValidSub = New-Item -Path "$Project\src\Utility" -ItemType Directory -Force
        'valid-code' | Out-File "$ValidSub\helper.ps1"
    }

    It "Should strictly exclude .git, Build, and Shared folders from the source" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Project -Destination $BuildDir
        $BuildRoot = "$BuildDir\DirtyProj"

        # Verify excluded directories do NOT exist
        Test-Path "$BuildRoot\.git"    | Should -Be $false
        Test-Path "$BuildRoot\Build"   | Should -Be $false
        
        # Verify the source's Shared folder was ignored 
        # (A Shared folder only appears in Build if created by the packer's Dependency logic)
        Test-Path "$BuildRoot\Shared"  | Should -Be $false
    }

    It "Should still correctly copy deep valid subfolders" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Project -Destination $BuildDir
        Test-Path "$BuildDir\DirtyProj\src\Utility\helper.ps1" | Should -Be $true
    }

    AfterAll {
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Packer Link Handling (Junctions) Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\PackerLinkTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: A Source folder and a Junction pointing to it ---
        # We create a folder outside the project tree to act as the "Target"
        $ExternalTarget = New-Item -Path "$TestRoot\ExternalTarget" -ItemType Directory -Force
        'linked-content' | Out-File "$ExternalTarget\data.txt"

        # Create the Project
        $Project = New-Item -Path "$MockRepo\LinkApp" -ItemType Directory -Force
        '@{ Version = "1.0.0" }' | Out-File "$Project\Manifest.psd1"

        # Create a Junction inside the project pointing to the external folder
        # Junctions are preferred over Symlinks in PS 5.1 because they don't require Admin
        New-Item -Path "$Project\LinkedFolder" -ItemType Junction -Value $ExternalTarget | Out-Null
    }

    It "Should flatten junctions into real directories and files in the build" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Project -Destination $BuildDir
        $BuildPath = "$BuildDir\LinkApp\LinkedFolder"

        # 1. Verify the folder exists in the build
        Test-Path $BuildPath | Should -Be $true

        # 2. Verify it is a REAL directory, not a link anymore
        # In PS 5.1, (Get-Item).LinkType is null for a standard directory
        $item = Get-Item $BuildPath
        $item.LinkType | Should -BeNullOrEmpty

        # 3. Verify the content was copied correctly
        Get-Content "$BuildPath\data.txt" | Should -Be "linked-content"
    }

    AfterAll {
        # Note: Be careful when deleting junctions; always use -Recurse -Force 
        # to ensure the link is removed without touching the original target
        Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Packer Mixed Dependency Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\MixedAssetTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: Different Dependency Types ---
        # 1. A Project (Has Manifest)
        $ProjLib = New-Item -Path "$MockRepo\External\ProjLib" -ItemType Directory -Force
        '@{ Version = "2.1.0" }' | Out-File "$ProjLib\Manifest.psd1"
        'function Get-Data { "data" }' | Out-File "$ProjLib\Lib.ps1"

        # 2. A Folder Asset (No Manifest)
        $FolderAsset = New-Item -Path "$MockRepo\External\Icons" -ItemType Directory -Force
        'image-data' | Out-File "$FolderAsset\logo.png"

        # 3. A File Asset (Single File)
        $FileAsset = New-Item -Path "$MockRepo\External\settings.json" -ItemType File -Force
        '{"theme":"dark"}' | Out-File $FileAsset

        # --- THE MAIN APP ---
        $App = New-Item -Path "$MockRepo\MainApp" -ItemType Directory -Force
        $ManifestContent = @"
@{ 
    Version = "1.0.0"; 
    Dependencies = @(
        "../External/ProjLib", 
        "../External/Icons", 
        "../External/settings.json"
    ) 
}
"@
        $ManifestContent | Out-File "$App\Manifest.psd1"
    }

    It "Should correctly package projects, folders, and files into Shared" {
    & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir
    $Shared = "$BuildDir\MainApp\Shared"

    # Verify Folder Asset structure (The logo should be directly inside Icons folder)
    Test-Path "$Shared\Icons\logo.png" | Should -Be $true
    
    # Verify File Asset structure (The json should be inside a folder named after it)
    Test-Path "$Shared\settings.json\settings.json" | Should -Be $true
}

It "Should map Paths.ps1 correctly for all three types" {
    . "$BuildDir\MainApp\Paths.ps1"

    $Paths.ProjLib | Should -Match "Shared\\ProjLib$"
    $Paths.Icons   | Should -Match "Shared\\Icons$"
    $Paths.'settings.json' | Should -Match "Shared\\settings.json\\settings.json$"
}


    AfterAll { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Packer Collision Guard Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\CollisionGuardTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # --- SETUP: Two items with the same leaf name 'Common' ---
        $Folder1 = New-Item -Path "$MockRepo\GroupA\Common" -ItemType Directory -Force
        'data-a' | Out-File "$Folder1\a.txt"

        $Folder2 = New-Item -Path "$MockRepo\GroupB\Common" -ItemType Directory -Force
        'data-b' | Out-File "$Folder2\b.txt"

        # Project depending on both
        $App = New-Item -Path "$MockRepo\CollisionApp" -ItemType Directory -Force
        '@{ Version="1.0"; Dependencies=@("../GroupA/Common", "../GroupB/Common") }' | Out-File "$App\Manifest.psd1"
    }

    It "Should throw a DEPENDENCY COLLISION error if names overlap" {
        { 
            & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir 
        } | Should -Throw -ExpectedMessage "*NAMING COLLISION*"
    }

    It "Should not leave a partial build if a collision is detected during validation" {
        # Note: Our script runs a validation pass before cleaning/building
        $GhostFolder = Join-Path $BuildDir "CollisionApp"
        
        # Ensure the build folder doesn't exist yet
        Test-Path $GhostFolder | Should -Be $false
    }

    AfterAll { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Packer Cross-Collision Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\CrossCollisionTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # External Lib named 'Core'
        $ExtCore = New-Item -Path "$MockRepo\External\Core" -ItemType Directory -Force
        '@{ Version="2.0" }' | Out-File "$ExtCore\Manifest.psd1"

        # App with internal folder named 'Core'
        $App = New-Item -Path "$MockRepo\App" -ItemType Directory -Force
        $InternalCore = New-Item -Path "$App\Core" -ItemType Directory -Force
        '@{ Version="1.0" }' | Out-File "$InternalCore\Manifest.psd1"

        # Manifest that tries to use BOTH
        '@{ 
            Version = "1.0"; 
            SubProjects = @("Core"); 
            Dependencies = @("../External/Core") 
        }' | Out-File "$App\Manifest.psd1"
    }

    It "Should throw an error if a SubProject and Dependency share the same name" {
        { 
            & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir 
        } | Should -Throw -ExpectedMessage "*NAMING COLLISION*"
    }

    AfterAll { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe "Packer Reserved Name Tests" {
    BeforeAll {
        $TestRoot = New-Item -Path "$env:TEMP\ReservedNameTests" -ItemType Directory -Force
        $MockRepo = New-Item -Path "$TestRoot\Repo" -ItemType Directory -Force
        $BuildDir = New-Item -Path "$TestRoot\Build" -ItemType Directory -Force

        # External Lib named 'Shared'
        $ExtShared = New-Item -Path "$MockRepo\External\Shared" -ItemType Directory -Force
        '@{ Version="1.0" }' | Out-File "$ExtShared\Manifest.psd1"

        # App manifest trying to use the reserved name
        $App = New-Item -Path "$MockRepo\App" -ItemType Directory -Force
        '@{ Version="1.0"; Dependencies=@("../External/Shared") }' | Out-File "$App\Manifest.psd1"
    }

    It "Should throw an error if a dependency is named 'Shared' or 'Paths'" {
        { 
            & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir 
        } | Should -Throw -ExpectedMessage "*NAMING COLLISION*"
    }

    AfterAll { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
