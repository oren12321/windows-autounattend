Describe "Expand-EmbeddedFiles" {

    BeforeAll {
        # Path to the function under test
        . "$PSScriptRoot\Expand-EmbeddedFiles.ps1"

        # Create a temp workspace
        $TestRoot = Join-Path $env:TEMP ("ExtractTest_" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $TestRoot | Out-Null

        # Prepare sample text content
        $Utf8Text   = 'UTF8 test content'
        $Utf16Text  = 'UTF16 test content'
        $DefaultTxt = 'Default ANSI text'

        # Prepare a small ZIP file
        $ZipSource = Join-Path $TestRoot "ZipSource"
        New-Item -ItemType Directory -Path $ZipSource | Out-Null

        $ZipInnerFile = Join-Path $ZipSource "inner.txt"
        Set-Content -Path $ZipInnerFile -Value "ZIP test content"

        $ZipPath = Join-Path $TestRoot "sample.zip"

        if (Test-Path $ZipPath) {
            Remove-Item $ZipPath -Force
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($ZipSource, $ZipPath)

        # Read original ZIP bytes for comparison
        $OriginalZipBytes = [IO.File]::ReadAllBytes($ZipPath)

        # Build XML with embedded files
        $xml = @"
<unattend>
  <Extensions>
    <File path="$TestRoot\script.ps1">$Utf8Text</File>
    <File path="$TestRoot\config.xml">$Utf8Text</File>
    <File path="$TestRoot\settings.reg">$Utf16Text</File>
    <File path="$TestRoot\script.vbs">$Utf16Text</File>
    <File path="$TestRoot\script.js">$Utf16Text</File>
    <File path="$TestRoot\notes.txt">$DefaultTxt</File>
    <File path="$TestRoot\archive.zip">$( [Convert]::ToBase64String($OriginalZipBytes) )</File>
  </Extensions>
</unattend>
"@

        $script:Document = [xml]$xml
        $script:TestRoot = $TestRoot
        $script:OriginalZipBytes = $OriginalZipBytes
        $script:Utf8Text = $Utf8Text
        $script:Utf16Text = $Utf16Text
        $script:DefaultTxt = $DefaultTxt
    }

    AfterAll {
        Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Extracts all embedded files correctly" {

        # Run the extractor
        Expand-EmbeddedFiles -Document $Document

        # --- UTF8 files ---
        Get-Content "$TestRoot\script.ps1" -Raw | Should -Be $Utf8Text
        Get-Content "$TestRoot\config.xml" -Raw | Should -Be $Utf8Text

        # --- UTF16 files ---
        $regBytes = [IO.File]::ReadAllBytes("$TestRoot\settings.reg")
        $regBytes[0..1] | Should -Be @(0xFF,0xFE)   # UTF16LE BOM
        (Get-Content "$TestRoot\settings.reg" -Raw) | Should -Be $Utf16Text

        # --- Default encoding file ---
        Get-Content "$TestRoot\notes.txt" -Raw | Should -Be $DefaultTxt

        # --- ZIP extraction ---
        $ExtractedZipBytes = [IO.File]::ReadAllBytes("$TestRoot\archive.zip")
        $ExtractedZipBytes | Should -Be $OriginalZipBytes
    }
}
