BeforeAll {
    . "$PSScriptRoot\..\Generate-Scripts.ps1"
}

Describe "Generate-Scripts" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("ScriptsTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Generates scripts only for passes with commands" {
        $groups = @{
            Specialize  = @(@{ Command="cmd1" })
            FirstLogon  = @()
            ActiveSetup = @(@{ Command="cmd2" })
        }

        $result = Generate-Scripts -Groups $groups -OutputFolder $TestRoot

        Test-Path $result.SpecializeScript  | Should -Be $true
        Test-Path $result.ActiveSetupScript | Should -Be $true
        $result.FirstLogonScript            | Should -Be $null
    }

    It "Writes commands in correct order" {
        $groups = @{
            Specialize = @(
                @{ Command="cmd1" },
                @{ Command="cmd2" }
            )
            FirstLogon  = @()
            ActiveSetup = @()
        }

        $result = Generate-Scripts -Groups $groups -OutputFolder $TestRoot

        $content = Get-Content $result.SpecializeScript
        $content[-2] | Should -Be "cmd1"
        $content[-1] | Should -Be "cmd2"
    }

    It "Creates the output folder if missing" {
        $folder = Join-Path $TestRoot "Missing"

        $groups = @{
            Specialize = @(@{ Command="cmd1" })
            FirstLogon = @()
            ActiveSetup = @()
        }

        $result = Generate-Scripts -Groups $groups -OutputFolder $folder

        Test-Path $folder | Should -Be $true
        Test-Path $result.SpecializeScript | Should -Be $true
    }
}
