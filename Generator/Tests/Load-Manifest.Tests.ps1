BeforeAll {
    . "$PSScriptRoot\..\Load-Manifest.ps1"
}

Describe "Load-Manifest" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("ManifestTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Loads a valid manifest" {
        $path = Join-Path $TestRoot "ProjA.psd1"
        @"
@{
    Commands = @()
}
"@ | Set-Content $path

        $result = Load-Manifest -ManifestPath $path

        $result | Should -BeOfType Hashtable
        $result.ContainsKey("Commands") | Should -Be $true
    }

    It "Throws if manifest file does not exist" {
        { Load-Manifest -ManifestPath (Join-Path $TestRoot "Missing.psd1") } | Should -Throw
    }

    It "Throws if manifest contains invalid PowerShell syntax" {
        $path = Join-Path $TestRoot "Bad.psd1"
        "This is not valid PowerShell" | Set-Content $path

        { Load-Manifest -ManifestPath $path 2>$null } | Should -Throw
    }

    It "Throws if manifest does not produce a hashtable" {
        $path = Join-Path $TestRoot "NotAHashtable.psd1"
        "12345" | Set-Content $path

        { Load-Manifest -ManifestPath $path 2>$null } | Should -Throw
    }
}
