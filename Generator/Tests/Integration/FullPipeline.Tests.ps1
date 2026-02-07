BeforeAll {
    . "$PSScriptRoot\..\..\Invoke-Generator.ps1"
}

Describe "Full Generator Pipeline Integration Test" {
    
    It "Runs the full pipeline and produces all expected artifacts" {
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
"@ | Set-Content (Join-Path $ProjA "Unattend.psd1")

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
"@ | Set-Content (Join-Path $ProjB "Unattend.psd1")

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
        $zipEntries.Count | Should -Eq 5 # 2 x Unattend.psd1 + 3 scripts
        ($zipEntries.Name -contains "Unattend.psd1") | Should -Be $true

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
        
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    It "Runs the full pipeline for empty build folder" {
        # Create a temporary workspace
        $TestRoot = Join-Path $env:TEMP ("GenInt_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        # Build folder
        $BuildRoot = Join-Path $TestRoot "Build"
        New-Item -ItemType Directory -Path $BuildRoot | Out-Null

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
        $zipEntries.Count | Should -Eq 3 # 3 scripts
        ($zipEntries.Name -contains "Specialize.ps1") | Should -Be $true
        ($zipEntries.Name -contains "FirstLogon.ps1") | Should -Be $true
        ($zipEntries.Name -contains "ActiveSetup.ps1") | Should -Be $true

        # --- Specialize script sorted correctly ---
        $spec = Get-Content $result.Scripts.SpecializeScript
        $spec.Count | Should -Be 2
        $spec[0] | Should -Be "# Auto-generated script for Specialize"
        $spec[1] | Should -Be ""

        # --- FirstLogon script contains command ---
        $spec = Get-Content $result.Scripts.FirstLogonScript
        $spec.Count | Should -Be 2
        $spec[0] | Should -Be "# Auto-generated script for FirstLogon"
        $spec[1] | Should -Be ""

        # --- ActiveSetup script contains command ---
        $spec = Get-Content $result.Scripts.ActiveSetupScript
        $spec.Count | Should -Be 2
        $spec[0] | Should -Be "# Auto-generated script for ActiveSetup"
        $spec[1] | Should -Be ""

        # --- XML sections embedded ---
        $xml = Get-Content $result.AutounattendPath -Raw

        $xml | Should -Match "RunSynchronous"
        $xml | Should -Match "FirstLogonCommands"
        $xml | Should -Match "C:\\Workspace"
        $xml | Should -Match "<File path="
        
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
