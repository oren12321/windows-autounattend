BeforeAll {
    . "$PSScriptRoot\..\..\Invoke-Generator.ps1"
}

Describe "Full Generator Pipeline Integration Test" {

    BeforeAll {
        # Create a temporary workspace
        $TestRoot = Join-Path $env:TEMP ("GenInt_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        # Build folder
        $BuildRoot = Join-Path $TestRoot "Build"
        New-Item -ItemType Directory -Path $BuildRoot | Out-Null

        # Project A
        $ProjA = Join-Path $BuildRoot "ProjA"
        New-Item -ItemType Directory -Path $ProjA | Out-Null

        @"
@{
    Commands = @(
        @{
            Pass    = 'Specialize'
            Order   = 2
            Command = 'cmdA2'
        },
        @{
            Pass    = 'Specialize'
            Order   = 1
            Command = 'cmdA1'
        },
        @{
            Pass    = 'FirstLogon'
            Order   = 5
            Command = 'cmdA5'
        }
    )
}
"@ | Set-Content (Join-Path $ProjA "ProjA.psd1")

        # Project B
        $ProjB = Join-Path $BuildRoot "ProjB"
        New-Item -ItemType Directory -Path $ProjB | Out-Null

        @"
@{
    Commands = @(
        @{
            Pass    = 'ActiveSetup'
            Order   = 10
            Command = 'cmdB10'
        }
    )
}
"@ | Set-Content (Join-Path $ProjB "ProjB.psd1")

        # Template XML
        $TemplatePath = Join-Path $TestRoot "Template.xml"
        @"
<root>
{{SPECIALIZE}}
{{FIRSTLOGON}}
{{WORKSPACE}}
{{EMBEDDEDZIP}}
</root>
"@ | Set-Content $TemplatePath

        # Output folder
        $OutputFolder = Join-Path $TestRoot "Out"
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null

        # Workspace path (target machine)
        $WorkspacePath = "C:\Workspace"

        # Store for tests
        $script:BuildRoot     = $BuildRoot
        $script:TemplatePath  = $TemplatePath
        $script:OutputFolder  = $OutputFolder
        $script:WorkspacePath = $WorkspacePath
    }

    AfterAll {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Runs the full pipeline and produces all expected artifacts" {

        $result = Invoke-Generator `
            -BuildRoot $BuildRoot `
            -TemplatePath $TemplatePath `
            -OutputFolder $OutputFolder `
            -WorkspacePath $WorkspacePath

        # --- Basic artifacts ---
        Test-Path $result.AutounattendPath | Should -Be $true
        Test-Path $result.ZipPath          | Should -Be $true

        # --- Scripts ---
        Test-Path $result.Scripts.SpecializeScript  | Should -Be $true
        Test-Path $result.Scripts.FirstLogonScript  | Should -Be $true
        Test-Path $result.Scripts.ActiveSetupScript | Should -Be $true

        # --- ZIP contains Build folder ---
        $zipEntries = [System.IO.Compression.ZipFile]::OpenRead($result.ZipPath).Entries
        ($zipEntries.Name -contains "ProjA.psd1") | Should -Be $true
        ($zipEntries.Name -contains "ProjB.psd1") | Should -Be $true

        # --- Specialize script sorted correctly ---
        $spec = Get-Content $result.Scripts.SpecializeScript
        $spec[-2] | Should -Be "cmdA1"
        $spec[-1] | Should -Be "cmdA2"

        # --- FirstLogon script contains command ---
        (Get-Content $result.Scripts.FirstLogonScript) -join "`n" |
            Should -Match "cmdA5"

        # --- ActiveSetup script contains command ---
        (Get-Content $result.Scripts.ActiveSetupScript) -join "`n" |
            Should -Match "cmdB10"

        # --- XML sections embedded ---
        $xml = Get-Content $result.AutounattendPath -Raw

        $xml | Should -Match "RunSynchronous"
        $xml | Should -Match "FirstLogonCommands"
        $xml | Should -Match "C:\\Workspace"
        $xml | Should -Match "<File path="
    }
}
