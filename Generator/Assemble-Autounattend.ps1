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

    if (-not (Test-Path $TemplatePath)) {
        throw "Template file '$TemplatePath' does not exist."
    }

    $xml = Get-Content -Path $TemplatePath -Raw

    $xml = $xml.Replace("{{SPECIALIZE}}",  $XmlSections.SpecializeXml)
    $xml = $xml.Replace("{{FIRSTLOGON}}",  $XmlSections.FirstLogonXml)
    $xml = $xml.Replace("{{ACTIVESETUP}}", $XmlSections.ActiveSetupXml)
    $xml = $xml.Replace("{{EMBEDDEDZIP}}", $EmbeddedZipXml)

    $xml | Set-Content -Path $OutputPath -Encoding UTF8

    return $xml
}
