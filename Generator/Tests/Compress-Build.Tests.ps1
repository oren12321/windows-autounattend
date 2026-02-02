BeforeAll {
    . "$PSScriptRoot\..\Compress-Build.ps1"
}

Describe "Compress-Build" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("CompressTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        $BuildRoot = Join-Path $TestRoot "Build"
        New-Item -ItemType Directory -Path $BuildRoot | Out-Null

        # Create sample files
        Set-Content -Path (Join-Path $BuildRoot "file1.txt") -Value "hello"
        New-Item -ItemType Directory -Path (Join-Path $BuildRoot "Sub") | Out-Null
        Set-Content -Path (Join-Path $BuildRoot "Sub\file2.txt") -Value "world"

        $script:BuildRoot = $BuildRoot
        $script:ZipPath = Join-Path $TestRoot "Build.zip"
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Creates a ZIP file" {
        $result = Compress-Build -BuildRoot $BuildRoot -OutputZipPath $ZipPath

        Test-Path $result | Should -Be $true
    }

    It "ZIP contains all files" {
        Compress-Build -BuildRoot $BuildRoot -OutputZipPath $ZipPath

        $entries = [System.IO.Compression.ZipFile]::OpenRead($ZipPath).Entries

        ($entries.Name -contains "file1.txt") | Should -Be $true
        ($entries.Name -contains "file2.txt") | Should -Be $true
    }

    It "Throws if Build root does not exist" {
        { Compress-Build -BuildRoot "C:\Missing" -OutputZipPath $ZipPath 2>$null } | Should -Throw
    }

    It "Creates output folder if missing" {
        $missingFolder = Join-Path $TestRoot "Missing"
        $zipPath2 = Join-Path $missingFolder "Build.zip"

        Compress-Build -BuildRoot $BuildRoot -OutputZipPath $zipPath2

        Test-Path $missingFolder | Should -Be $true
        Test-Path $zipPath2      | Should -Be $true
    }

    It "Overwrites existing ZIP" {
        # Create a dummy ZIP first
        Set-Content -Path $ZipPath -Value "dummy"

        Compress-Build -BuildRoot $BuildRoot -OutputZipPath $ZipPath

        # ZIP should now be valid, not the dummy file
        $entries = [System.IO.Compression.ZipFile]::OpenRead($ZipPath).Entries
        $entries.Count | Should -BeGreaterThan 0
    }
}
