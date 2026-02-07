BeforeAll {
    . "$PSScriptRoot\..\Embed-Zip.ps1"
}

Describe "Embed-Zip" {

    BeforeEach {
        $TestRoot = Join-Path $env:TEMP ("EmbedZipTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        $ZipPath = Join-Path $TestRoot "Build.zip"

        # Create a tiny ZIP
        $tempFile = Join-Path $TestRoot "file.txt"
        Set-Content -Path $tempFile -Value "hello"

        Compress-Archive -Path $tempFile -DestinationPath $ZipPath

        $script:ZipPath = $ZipPath
        $script:Dest = "C:\Windows\Setup\Scripts\Build.zip"
    }

    AfterEach {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Throws if ZIP does not exist" {
        { Embed-Zip -ZipPath "C:\Missing.zip" -DestinationPath $Dest 2>$null } | Should -Throw
    }

    It "Returns XML containing the destination path" {
        $xml = Embed-Zip -ZipPath $ZipPath -DestinationPath $Dest

        $xml | Should -Match "path=\""$([regex]::Escape($Dest))\"""
    }

    It "Embeds base64 content inside CDATA" {
        $xml = Embed-Zip -ZipPath $ZipPath -DestinationPath $Dest

        $xml | Should -Match "<!\[CDATA\[.*\]\]>"
    }

    It "Base64 content matches the ZIP file" {
        $xml = Embed-Zip -ZipPath $ZipPath -DestinationPath $Dest

        # Extract base64 from XML
        $base64 = ($xml -split "<!\[CDATA\[" -split "\]\]>" )[1]

        $decoded = [System.Convert]::FromBase64String($base64)

        $decoded.Length | Should -Be ([System.IO.File]::ReadAllBytes($ZipPath).Length)
    }
}
