param(
    [string]$BuildRoot = "C:\Build",
    [string]$TemplatePath = "$PSScriptRoot\Template.xml",
    [string]$OutputFolder = "C:\Out",
    [string]$WorkspacePath = "C:\Windows\Setup\Scripts"
)

. "$PSScriptRoot\Invoke-Generator.ps1"

Invoke-Generator `
    -BuildRoot $BuildRoot `
    -TemplatePath $TemplatePath `
    -OutputFolder $OutputFolder `
    -WorkspacePath $WorkspacePath