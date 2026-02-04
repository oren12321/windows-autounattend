. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Assembles the final autounattend.xml file.

.DESCRIPTION
    Assemble-Autounattend is the eleventh stage in the autounattend generator
    pipeline. It takes a template autounattend.xml file and replaces placeholder
    tokens with generated XML fragments:

        {{SPECIALIZE}}
        {{FIRSTLOGON}}
        {{ACTIVESETUP}}
        {{EMBEDDEDZIP}}

    The resulting XML is written to disk and also returned as a string.

.PARAMETER TemplatePath
    Path to the autounattend.xml template file.

.PARAMETER OutputPath
    Path where the final autounattend.xml should be written.

.PARAMETER XmlSections
    Hashtable containing:
        SpecializeXml
        FirstLogonXml
        ActiveSetupXml

.PARAMETER EmbeddedZipXml
    XML <File> element containing the embedded ZIP.

.OUTPUTS
    String containing the final autounattend.xml content.

.EXAMPLE
    Assemble-Autounattend -TemplatePath "Template.xml" `
                          -OutputPath "autounattend.xml" `
                          -XmlSections $sections `
                          -EmbeddedZipXml $zipXml
#>
function Assemble-Autounattend {
    param(
        [Parameter(Mandatory)]
        [string] $TemplatePath,

        [Parameter(Mandatory)]
        [string] $OutputPath,

        [Parameter(Mandatory)]
        [hashtable] $XmlSections,

        [Parameter(Mandatory)]
        [string] $EmbeddedZipXml
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Assembling autounattend.xml using template '$TemplatePath'")

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Checking if template file exists")
    if (-not (Test-Path $TemplatePath)) {
        throw "Template file '$TemplatePath' does not exist."
    }

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Loading template content")
    $xml = Get-Content -Path $TemplatePath -Raw

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Injecting Specialize XML section")
    $xml = $xml.Replace("{{SPECIALIZE}}", $XmlSections.SpecializeXml)

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Injecting FirstLogon XML section")
    $xml = $xml.Replace("{{FIRSTLOGON}}", $XmlSections.FirstLogonXml)

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Embedding ZIP payload XML")
    $xml = $xml.Replace("{{EMBEDDEDZIP}}", $EmbeddedZipXml)
    
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Injecting workspace folder for bootstrap script")
    $xml = $xml.Replace("{{WORKSPACE}}", $XmlSections.WorkspacePath)

    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Writing final autounattend.xml to '$OutputPath'")
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($OutputPath, $xml, $Utf8NoBom)

    Write-Timestamped (Format-Line -Level "INFO" -Message "Autounattend assembly complete")

    return $xml
}
