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
        
        '@{ ModuleVersion = "1.0.0"; RequiredModules=@("../ProjB", "../ProjC") }' | Out-File "$MockRepo\ProjA\ProjA.psd1"
        '@{ ModuleVersion = "1.0.0"; RequiredModules=@("../ProjD") }'              | Out-File "$MockRepo\ProjB\ProjB.psd1"
        '@{ ModuleVersion = "1.0.0"; RequiredModules=@("../ProjD") }'              | Out-File "$MockRepo\ProjC\ProjC.psd1"
        '@{ ModuleVersion = "1.0.0" }'                                            | Out-File "$MockRepo\ProjD\ProjD.psd1"

        # --- SETUP: Circular Dependency ---
        # ProjLoop1 -> ProjLoop2 -> ProjLoop1
        New-Item -Path "$MockRepo\ProjLoop1" -ItemType Directory | Out-Null
        New-Item -Path "$MockRepo\ProjLoop2" -ItemType Directory | Out-Null
        '@{ ModuleVersion = "1.0.0"; RequiredModules=@("../ProjLoop2") }' | Out-File "$MockRepo\ProjLoop1\ProjLoop1.psd1"
        '@{ ModuleVersion = "1.0.0"; RequiredModules=@("../ProjLoop1") }' | Out-File "$MockRepo\ProjLoop2\ProjLoop2.psd1"
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
    
    It "Should generate a manifest only for the root project" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -Destination $BuildDir

        $RootManifest = "$BuildDir\ProjA\ProjA.psd1"
        $DepManifestB = "$BuildDir\ProjA\Shared\ProjB\ProjB.psd1"
        $DepManifestC = "$BuildDir\ProjA\Shared\ProjC\ProjC.psd1"
        $DepManifestD1 = "$BuildDir\ProjA\Shared\ProjB\Shared\ProjD\ProjD.psd1"
        $DepManifestD2 = "$BuildDir\ProjA\Shared\ProjC\Shared\ProjD\ProjD.psd1"

        Test-Path $RootManifest | Should -Be $true
        Test-Path $DepManifestB | Should -Be $false
        Test-Path $DepManifestC | Should -Be $false
        Test-Path $DepManifestD1 | Should -Be $false
        Test-Path $DepManifestD2 | Should -Be $false
    }
    
    It "Should name the manifest after the project" {
        & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -Destination $BuildDir

        Test-Path "$BuildDir\ProjA\ProjA.psd1" | Should -Be $true
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
        '@{ ModuleVersion = "2.5.4" }' | Out-File "$DepA\DepA.psd1"

        # Setup Main Project
        $Main = New-Item -Path "$MockRepo\MainApp" -ItemType Directory -Force
        '@{ ModuleVersion = "1.0.0"; RequiredModules = @("../DepA") }' | Out-File "$Main\MainApp.psd1"
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

    It "Should throw an error if ModuleVersion is missing" {
        $NoVer = New-Item -Path "$MockRepo\NoVer" -ItemType Directory -Force
        '@{ RequiredModules = @() }' | Out-File "$NoVer\NoVer.psd1" # Missing Version

        { & "$PSScriptRoot\Pack.ps1" -ProjectPath $NoVer } | Should -Throw -ExpectedMessage "*VERSION REQUIRED*"
    }

    It "Should list all unique dependencies when -ListAvailable is used" {
        # Setup tree: A -> B -> C
        foreach($p in 'A','B','C') { 
            $folder = New-Item -Path "$MockRepo\Proj$p" -ItemType Directory -Force
            $ver = "1.0.$p"
            $req = if($p -eq 'A'){"@('../ProjB')"} elseif($p -eq 'B'){"@('../ProjC')"} else{"@()"}
            "@{ ModuleVersion='$ver'; RequiredModules=$req }" | Out-File "$folder\Proj$p.psd1"
        }

        $output = & "$PSScriptRoot\Pack.ps1" -ProjectPath "$MockRepo\ProjA" -ListAvailable
        $output | Should -Contain "ProjA                v1.0.A"
        $output | Should -Contain "ProjB                v1.0.B"
        $output | Should -Contain "ProjC                v1.0.C"
    }
    
    It "Should include all custom metadata except ModuleVersion and RequiredModules" {
        $Proj = New-Item -Path "$MockRepo\MetaTest" -ItemType Directory -Force
'@{
    ModuleVersion   = "1.0.0"
    RequiredModules = @()
    DeploymentPass  = "Specialize"
    Order           = 5
    ActiveSetup     = $true
    Notes           = "Custom metadata"
}' | Out-File "$Proj\MetaTest.psd1"

        & "$PSScriptRoot\Pack.ps1" -ProjectPath $Proj -Destination $BuildDir

        $ManifestPath = "$BuildDir\MetaTest\MetaTest.psd1"
        $Manifest = Import-PowerShellDataFile $ManifestPath

        $Manifest.Keys | Should -Contain "DeploymentPass"
        $Manifest.Keys | Should -Contain "Order"
        $Manifest.Keys | Should -Contain "ActiveSetup"
        $Manifest.Keys | Should -Contain "Notes"

        $Manifest.Keys | Should -Not -Contain "ModuleVersion"
        $Manifest.Keys | Should -Not -Contain "RequiredModules"
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
        '@{ ModuleVersion="1.0.0"; RequiredModules=@("../LibA") }' | Out-File "$App\App.psd1"
        '@{ ModuleVersion="2.1.0"; RequiredModules=@("../LibB") }' | Out-File "$LibA\LibA.psd1"
        '@{ ModuleVersion="3.0.5"; RequiredModules=@() }'           | Out-File "$LibB\LibB.psd1"
        
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
            '@{ RequiredModules=@() }' | Out-File "$Broken\Broken.psd1" # Missing ModuleVersion

            { 
                & "$PSScriptRoot\Pack.ps1" -ProjectPath $Broken -ListAvailable 
            } | Should -Throw -ExpectedMessage "*VERSION REQUIRED*"
        }
    }
    
    It "Should NOT generate a manifest during -ListAvailable" {
        $Output = & "$PSScriptRoot\Pack.ps1" -ProjectPath $App -Destination $BuildDir -ListAvailable

        $ManifestPath = "$BuildDir\App\App.psd1"
        Test-Path $ManifestPath | Should -Be $false
    }

    AfterAll {
        # Cleanup
        if (Test-Path $TestRoot) { 
            Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue 
        }
    }
}
