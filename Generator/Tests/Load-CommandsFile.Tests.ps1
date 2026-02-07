BeforeAll {
    . "$PSScriptRoot\..\Load-CommandsFile.ps1"
}

Describe "Load-CommandsFile" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("ManifestTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Loads a valid commands file" {
        $path = Join-Path $TestRoot "Commands.psd1"
        @"
@{
    Commands = @()
}
"@ | Set-Content $path

        $result = Load-Manifest -CommandsFilePath $path

        $result | Should -BeOfType Hashtable
        $result.ContainsKey("Commands") | Should -Be $true
    }

    It "Throws if commands file does not exist" {
        { Load-Manifest -CommandsFilePath (Join-Path $TestRoot "Missing.psd1") } | Should -Throw
    }

    It "Throws if commands file contains invalid PowerShell syntax" {
        $path = Join-Path $TestRoot "Bad.psd1"
        "This is not valid PowerShell" | Set-Content $path

        { Load-Manifest -CommandsFilePath $path 2>$null } | Should -Throw
    }

    It "Throws if commands file does not produce a hashtable" {
        $path = Join-Path $TestRoot "NotAHashtable.psd1"
        "12345" | Set-Content $path

        { Load-Manifest -CommandsFilePath $path 2>$null } | Should -Throw
    }
}
