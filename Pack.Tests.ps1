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
        
        '@{ RequiredModules=@("../ProjB", "../ProjC") }' | Out-File "$MockRepo\ProjA\ProjA.psd1"
        '@{ RequiredModules=@("../ProjD") }'              | Out-File "$MockRepo\ProjB\ProjB.psd1"
        '@{ RequiredModules=@("../ProjD") }'              | Out-File "$MockRepo\ProjC\ProjC.psd1"
        '@{ }'                                            | Out-File "$MockRepo\ProjD\ProjD.psd1"

        # --- SETUP: Circular Dependency ---
        # ProjLoop1 -> ProjLoop2 -> ProjLoop1
        New-Item -Path "$MockRepo\ProjLoop1" -ItemType Directory | Out-Null
        New-Item -Path "$MockRepo\ProjLoop2" -ItemType Directory | Out-Null
        '@{ RequiredModules=@("../ProjLoop2") }' | Out-File "$MockRepo\ProjLoop1\ProjLoop1.psd1"
        '@{ RequiredModules=@("../ProjLoop1") }' | Out-File "$MockRepo\ProjLoop2\ProjLoop2.psd1"
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
