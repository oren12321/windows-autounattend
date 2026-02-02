<#
.SYNOPSIS
    Embeds a ZIP file into an XML <File> element.

.DESCRIPTION
    Embed-Zip is the eighth stage in the autounattend generator pipeline.
    It reads a ZIP file, base64-encodes its contents, and returns an XML
    <File> element containing the encoded data inside a CDATA block.

    This XML fragment will later be inserted into autounattend.xml so that
    Windows Setup can write the ZIP file to disk during the Specialize pass.

.PARAMETER ZipPath
    Full path to the ZIP file to embed.

.PARAMETER DestinationPath
    The path where Windows Setup should write the ZIP file.

.OUTPUTS
    A string containing an XML <File> element.

.EXAMPLE
    $xml = Embed-Zip -ZipPath "C:\Build.zip" `
                     -DestinationPath "C:\Windows\Setup\Scripts\Build.zip"

.NOTES
    This function does not write any files. It only returns XML text.
#>
function Embed-Zip {
    param(
        [Parameter(Mandatory)]
        [string] $ZipPath,

        [Parameter(Mandatory)]
        [string] $DestinationPath
    )

    if (-not (Test-Path $ZipPath)) {
        throw "ZIP file '$ZipPath' does not exist."
    }

    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    $base64 = [System.Convert]::ToBase64String($bytes)

    $xml = @"
<File>
  <Path>$DestinationPath</Path>
  <Content><![CDATA[$base64]]></Content>
</File>
"@

    return $xml
}
