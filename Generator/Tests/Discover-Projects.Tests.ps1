BeforeAll {
    . "$PSScriptRoot\..\Discover-Projects.ps1"
}

Describe "Discover-Projects" {

    BeforeEach {
        # Create a temporary Build root for each test
        $TestRoot = Join-Path $env:TEMP ("BuildTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null
    }

    AfterEach {
        # Cleanup
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Finds valid projects" {
        $projA = Join-Path $TestRoot "ProjA"
        $projB = Join-Path $TestRoot "ProjB"
        $projC = Join-Path "$projB\Others" "ProjC"

        New-Item -ItemType Directory -Path $projA | Out-Null
        New-Item -ItemType Directory -Path $projB | Out-Null
        New-Item -ItemType Directory -Path $projC | Out-Null

        New-Item -ItemType File -Path (Join-Path $projA "Unattend.psd1") | Out-Null
        New-Item -ItemType File -Path (Join-Path $projB "Unattend.psd1") | Out-Null
        New-Item -ItemType File -Path (Join-Path $projC "Unattend.psd1") | Out-Null

        $result = Discover-Projects -BuildRoot $TestRoot

        $result.Count | Should -Be 3
        $result.Name | Should -Contain "ProjA"
        $result.Name | Should -Contain "ProjB"
        $result.Name | Should -Contain "ProjC"
    }

    It "Ignores Shared and .git folders" {
        $shared = Join-Path $TestRoot "Shared"
        New-Item -ItemType Directory -Path $shared | Out-Null

        $projC = Join-Path $shared "ProjC"
        New-Item -ItemType Directory -Path $projC | Out-Null
        New-Item -ItemType File -Path (Join-Path $projC "Unattend.psd1") | Out-Null
        
        $git = Join-Path $projC ".git"
        New-Item -ItemType Directory -Path $git | Out-Null
        
        $projD = Join-Path $git "ProjD"
        New-Item -ItemType Directory -Path $projD | Out-Null
        New-Item -ItemType File -Path (Join-Path $projD "Unattend.psd1") | Out-Null
        
        $result = Discover-Projects -BuildRoot $TestRoot

        $result.Count | Should -Be 0
    }

    It "Ignores folders without manifest" {
        $projA = Join-Path $TestRoot "ProjA"
        New-Item -ItemType Directory -Path $projA | Out-Null

        $result = Discover-Projects -BuildRoot $TestRoot

        $result.Count | Should -Be 0
    }

    It "Ignores folders with mismatched manifest name" {
        $projA = Join-Path $TestRoot "ProjA"
        New-Item -ItemType Directory -Path $projA | Out-Null

        New-Item -ItemType File -Path (Join-Path $projA "Other.psd1") | Out-Null

        $result = Discover-Projects -BuildRoot $TestRoot

        $result.Count | Should -Be 0
    }

    It "Throws if Build root does not exist" {
        { Discover-Projects -BuildRoot "C:\Does\Not\Exist" } | Should -Throw
    }
}
