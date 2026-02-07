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

    Write-Information "[INFO] Starting autounattend generation pipeline"

    Write-Information "[DEBUG] Ensuring output folder exists"
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        Write-Information "[DEBUG] Created output folder '$OutputFolder'"
    }

    #
    # 1. Discover projects
    #
    Write-Information "[INFO] Stage 1: Discovering projects"
    $projects = Discover-Projects -BuildRoot $BuildRoot
    Write-Information "[INFO] Discovered $($projects.Count) project(s)"

    #
    # 2. Load manifests
    #
    Write-Information "[INFO] Stage 2: Loading project manifests"
    foreach ($proj in $projects) {
        Write-Information "[DEBUG] Loading manifest for project '$($proj.Name)'"
        $proj.Manifest = Load-Manifest -ManifestPath $proj.ManifestPath
    }

    #
    # 3. Validate manifests
    #
    Write-Information "[INFO] Stage 3: Validating manifests"
    foreach ($proj in $projects) {
        Write-Information "[DEBUG] Validating manifest for project '$($proj.Name)'"
        Validate-Manifest -Manifest $proj.Manifest -ProjectName $proj.Name
    }

    #
    # 4. Normalize commands
    #
    Write-Information "[INFO] Stage 4: Normalizing commands"
    
    $normalized = Normalize-Commands -Projects $projects
    Write-Information "[INFO] Normalized $($normalized.Count) command(s)"

    #
    # 5. Group commands
    #
    Write-Information "[INFO] Stage 5: Grouping commands by pass"
    $groups = Group-Commands -NormalizedCommands $normalized

    #
    # 6. Generate scripts
    #
    Write-Information "[INFO] Stage 6: Generating scripts"
    $scripts = Generate-Scripts -Groups $groups -OutputFolder $BuildRoot

    #
    # 7. Compress build
    #
    Write-Information "[INFO] Stage 7: Compressing build workspace"
    $zipPath = Join-Path $OutputFolder "Build.zip"
    Compress-Build -BuildRoot $BuildRoot -OutputZipPath $zipPath

    #
    # 8. Embed ZIP
    #
    Write-Information "[INFO] Stage 8: Embedding ZIP into XML"
    $embeddedZipXml = Embed-Zip -ZipPath $zipPath `
                                -DestinationPath "C:\Windows\Setup\Scripts\Build.zip"

    #
    # 9. Generate XML sections
    #
    Write-Information "[INFO] Stage 9: Generating XML sections"
    $xmlSections = Generate-XmlSections `
        -WorkspacePath $WorkspacePath `
        -SpecializeScriptPath "$WorkspacePath\Specialize.ps1" `
        -FirstLogonScriptPath "$WorkspacePath\FirstLogon.ps1"

    #
    # 10. Assemble autounattend.xml
    #
    Write-Information "[INFO] Stage 10: Assembling autounattend.xml"
    $autounattendPath = Join-Path $OutputFolder "autounattend.xml"

    Assemble-Autounattend `
        -TemplatePath $TemplatePath `
        -OutputPath $autounattendPath `
        -XmlSections $xmlSections `
        -EmbeddedZipXml $embeddedZipXml | Out-Null

    Write-Information "[INFO] Pipeline completed successfully"

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
