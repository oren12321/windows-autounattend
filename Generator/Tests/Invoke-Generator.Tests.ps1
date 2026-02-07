BeforeAll {
    . "$PSScriptRoot\..\Invoke-Generator.ps1"
}

Describe "Invoke-Generator" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("GenTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        # Build folder
        $Build = Join-Path $TestRoot "Build"
        New-Item -ItemType Directory -Path $Build | Out-Null

        # Project A
        $ProjA = Join-Path $Build "ProjA"
        New-Item -ItemType Directory -Path $ProjA | Out-Null

        @"
@{
    Commands = @(
        @{
            Pass    = "Specialize"
            Order   = 1
            Command = "cmdA"
        }
    )
}
"@ | Set-Content (Join-Path $ProjA "Unattend.psd1")

        # Template
        $Template = Join-Path $TestRoot "Template.xml"
        @"
<root>
{{SPECIALIZE}}
{{FIRSTLOGON}}
{{ACTIVESETUP}}
{{EMBEDDEDZIP}}
</root>
"@ | Set-Content $Template

        $script:BuildRoot = $Build
        $script:Template  = $Template
        $script:Output    = Join-Path $TestRoot "Out"
        $script:Workspace = "C:\Workspace"
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Runs the full pipeline and produces autounattend.xml" {
        $result = Invoke-Generator `
            -BuildRoot $BuildRoot `
            -TemplatePath $Template `
            -OutputFolder $Output `
            -WorkspacePath $Workspace

        Test-Path $result.AutounattendPath | Should -Be $true
        Test-Path $result.ZipPath          | Should -Be $true
        $result.Scripts.SpecializeScript   | Should -Not -Be $null
    }
}
