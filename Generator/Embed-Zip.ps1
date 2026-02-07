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

    Write-Information "[INFO] Embedding ZIP file '$ZipPath' into unattend XML"

    Write-Information "[DEBUG] Checking if ZIP file exists"
    if (-not (Test-Path $ZipPath)) {
        throw "ZIP file '$ZipPath' does not exist."
    }

    Write-Information "[DEBUG] Reading ZIP file bytes"
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)

    Write-Information "[DEBUG] Converting ZIP file to Base64"
    $base64 = [System.Convert]::ToBase64String($bytes)

    Write-Information "[DEBUG] Building XML wrapper for embedded ZIP targeting '$DestinationPath'"
    $xml = @"
<File path="$DestinationPath">
<![CDATA[$base64]]>
</File>
"@

    Write-Information "[INFO] ZIP embedding complete"
    return $xml
}
