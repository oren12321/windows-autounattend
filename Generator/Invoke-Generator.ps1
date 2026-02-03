. "$PSScriptRoot\Discover-Projects.ps1"
. "$PSScriptRoot\Load-Manifest.ps1"
. "$PSScriptRoot\Validate-Manifest.ps1"
. "$PSScriptRoot\Normalize-Commands.ps1"
. "$PSScriptRoot\Group-Commands.ps1"
. "$PSScriptRoot\Generate-Scripts.ps1"
. "$PSScriptRoot\Compress-Build.ps1"
. "$PSScriptRoot\Embed-Zip.ps1"
. "$PSScriptRoot\Generate-XmlSections.ps1"
. "$PSScriptRoot\Assemble-Autounattend.ps1"

<#
.SYNOPSIS
    Orchestrates the entire autounattend generation pipeline.

.DESCRIPTION
    Invoke-Generator is the twelfth and final stage in the autounattend
    generator pipeline. It coordinates all previous components:

        1. Discover projects
        2. Load manifests
        3. Validate manifests
        4. Normalize commands
        5. Group commands
        6. Generate scripts
        7. Compress build
        8. Embed ZIP
        9. Generate XML sections
       10. Assemble autounattend.xml

    It returns a structured object containing all intermediate and final
    artifacts.

.PARAMETER BuildRoot
    Path to the packed Build folder.

.PARAMETER TemplatePath
    Path to the autounattend.xml template.

.PARAMETER OutputFolder
    Folder where scripts, ZIP, and final XML will be written.

.PARAMETER WorkspacePath
    Path where Build.zip will be extracted on the target machine.

.OUTPUTS
    Hashtable containing all pipeline artifacts.

.EXAMPLE
    Invoke-Generator -BuildRoot "C:\Build" `
                     -TemplatePath "Template.xml" `
                     -OutputFolder "C:\Out" `
                     -WorkspacePath "C:\Workspace"
#>
function Invoke-Generator {
    param(
        [Parameter(Mandatory)]
        [string] $BuildRoot,

        [Parameter(Mandatory)]
        [string] $TemplatePath,

        [Parameter(Mandatory)]
        [string] $OutputFolder,

        [Parameter(Mandatory)]
        [string] $WorkspacePath
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    #
    # 1. Discover projects
    #
    $projects = Discover-Projects -BuildRoot $BuildRoot

    #
    # 2. Load manifests
    #
    foreach ($proj in $projects) {
        $proj.Manifest = Load-Manifest -ManifestPath $proj.ManifestPath
    }

    #
    # 3. Validate manifests
    #
    foreach ($proj in $projects) {
        Validate-Manifest -Manifest $proj.Manifest -ProjectName $proj.Name
    }

    #
    # 4. Normalize commands
    #
    $normalized = Normalize-Commands -Projects $projects

    #
    # 5. Group commands
    #
    $groups = Group-Commands -NormalizedCommands $normalized

    #
    # 6. Generate scripts
    #
    $scripts = Generate-Scripts -Groups $groups -OutputFolder $BuildRoot

    #
    # 7. Compress build
    #
    $zipPath = Join-Path $OutputFolder "Build.zip"
    Compress-Build -BuildRoot $BuildRoot -OutputZipPath $zipPath

    #
    # 8. Embed ZIP
    #
    $embeddedZipXml = Embed-Zip -ZipPath $zipPath `
                                -DestinationPath "C:\Windows\Setup\Scripts\Build.zip"

    #
    # 9. Generate XML sections
    #
    $xmlSections = Generate-XmlSections `
        -Groups $groups `
        -BootstrapScriptPath "C:\Windows\Setup\Scripts\Bootstrap.ps1" `
        -FirstLogonScriptPath "C:\Windows\Setup\Scripts\FirstLogon.ps1" `
        -ActiveSetupScriptPath "C:\Windows\Setup\Scripts\ActiveSetup.ps1"

    #
    # 10. Assemble autounattend.xml
    #
    $autounattendPath = Join-Path $OutputFolder "autounattend.xml"

    Assemble-Autounattend `
        -TemplatePath $TemplatePath `
        -OutputPath $autounattendPath `
        -XmlSections $xmlSections `
        -EmbeddedZipXml $embeddedZipXml | Out-Null

    #
    # Return everything
    #
    return @{
        Projects         = $projects
        Normalized       = $normalized
        Groups           = $groups
        Scripts          = $scripts
        ZipPath          = $zipPath
        EmbeddedZipXml   = $embeddedZipXml
        XmlSections      = $xmlSections
        AutounattendPath = $autounattendPath
    }
}
