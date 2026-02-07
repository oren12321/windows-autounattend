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

    Write-Information "[INFO] Assembling autounattend.xml using template '$TemplatePath'"

    Write-Information "[DEBUG] Checking if template file exists"
    if (-not (Test-Path $TemplatePath)) {
        throw "Template file '$TemplatePath' does not exist."
    }

    Write-Information "[DEBUG] Loading template content"
    $xml = Get-Content -Path $TemplatePath -Raw

    Write-Information "[DEBUG] Injecting Specialize XML section"
    $xml = $xml.Replace("{{SPECIALIZE}}", $XmlSections.SpecializeXml)

    Write-Information "[DEBUG] Injecting FirstLogon XML section"
    $xml = $xml.Replace("{{FIRSTLOGON}}", $XmlSections.FirstLogonXml)

    Write-Information "[DEBUG] Embedding ZIP payload XML"
    $xml = $xml.Replace("{{EMBEDDEDZIP}}", $EmbeddedZipXml)
    
    Write-Information "[DEBUG] Injecting workspace folder for bootstrap script"
    $xml = $xml.Replace("{{WORKSPACE}}", $XmlSections.WorkspacePath)

    Write-Information "[DEBUG] Writing final autounattend.xml to '$OutputPath'"
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($OutputPath, $xml, $Utf8NoBom)

    Write-Information "[INFO] Autounattend assembly complete"

    return $xml
}
