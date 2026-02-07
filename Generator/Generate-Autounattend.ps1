param(
    [string]$BuildRoot = "C:\Build",
    [string]$TemplatePath = "$PSScriptRoot\Template.xml",
    [string]$OutputFolder = "C:\Out",
    [string]$WorkspacePath = "C:\Windows\Setup\Scripts"
)

. "$PSScriptRoot\Invoke-Generator.ps1"

Write-Information "[INFO] Starting generator entry point"
Write-Information "[DEBUG] Parameters:"
Write-Information "[DEBUG]   BuildRoot     = $BuildRoot"
Write-Information "[DEBUG]   TemplatePath  = $TemplatePath"
Write-Information "[DEBUG]   OutputFolder  = $OutputFolder"
Write-Information "[DEBUG]   WorkspacePath = $WorkspacePath"

try {
    $result = Invoke-Generator `
        -BuildRoot $BuildRoot `
        -TemplatePath $TemplatePath `
        -OutputFolder $OutputFolder `
        -WorkspacePath $WorkspacePath

    Write-Information "[INFO] Generator completed successfully"
    return $result
}
catch {
    Write-Information "[ERROR] Generator failed: $($_.Exception.Message)"
    throw
}