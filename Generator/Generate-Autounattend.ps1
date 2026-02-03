. "$PSScriptRoot\..\Vendor\Logging.ps1"

param(
    [string]$BuildRoot = "C:\Build",
    [string]$TemplatePath = "$PSScriptRoot\Template.xml",
    [string]$OutputFolder = "C:\Out",
    [string]$WorkspacePath = "C:\Windows\Setup\Scripts"
)

. "$PSScriptRoot\Invoke-Generator.ps1"

Write-Timestamped (Format-Line -Level "INFO" -Message "Starting generator entry point")
Write-Timestamped (Format-Line -Level "DEBUG" -Message "Parameters:")
Write-Timestamped (Format-Line -Level "DEBUG" -Message "  BuildRoot     = $BuildRoot")
Write-Timestamped (Format-Line -Level "DEBUG" -Message "  TemplatePath  = $TemplatePath")
Write-Timestamped (Format-Line -Level "DEBUG" -Message "  OutputFolder  = $OutputFolder")
Write-Timestamped (Format-Line -Level "DEBUG" -Message "  WorkspacePath = $WorkspacePath")

try {
    $result = Invoke-Generator `
        -BuildRoot $BuildRoot `
        -TemplatePath $TemplatePath `
        -OutputFolder $OutputFolder `
        -WorkspacePath $WorkspacePath

    Write-Timestamped (Format-Line -Level "INFO" -Message "Generator completed successfully")
    return $result
}
catch {
    Write-Timestamped (Format-Line -Level "ERROR" -Message "Generator failed: $($_.Exception.Message)")
    throw
}