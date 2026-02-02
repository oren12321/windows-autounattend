BeforeAll {
    . "$PSScriptRoot\..\Generate-Bootstrap.ps1"
}

Describe "Generate-Bootstrap" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("BootstrapTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        $script:OutputFolder = $TestRoot
        $script:Workspace = "C:\Workspace"
        $script:Zip = "C:\Windows\Setup\Scripts\Build.zip"
        $script:Spec = "C:\Workspace\Specialize.ps1"
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Creates Bootstrap.ps1" {
        $path = Generate-Bootstrap -OutputFolder $OutputFolder `
                                   -WorkspacePath $Workspace `
                                   -ZipPath $Zip `
                                   -SpecializeScriptPath $Spec

        Test-Path $path | Should -Be $true
    }

    It "Contains workspace creation command" {
        $path = Generate-Bootstrap -OutputFolder $OutputFolder `
                                   -WorkspacePath $Workspace `
                                   -ZipPath $Zip `
                                   -SpecializeScriptPath $Spec

        (Get-Content $path) -join "`n" | Should -Match "New-Item -ItemType Directory -Path `"$([regex]::Escape($Workspace))`""
    }

    It "Contains Expand-Archive command" {
        $path = Generate-Bootstrap -OutputFolder $OutputFolder `
                                   -WorkspacePath $Workspace `
                                   -ZipPath $Zip `
                                   -SpecializeScriptPath $Spec

        (Get-Content $path) -join "`n" | Should -Match "Expand-Archive -Path `"$([regex]::Escape($Zip))`""
    }

    It "Contains call to Specialize.ps1" {
        $path = Generate-Bootstrap -OutputFolder $OutputFolder `
                                   -WorkspacePath $Workspace `
                                   -ZipPath $Zip `
                                   -SpecializeScriptPath $Spec

        (Get-Content $path) -join "`n" | Should -Match "& `"$([regex]::Escape($Spec))`""
    }
}
