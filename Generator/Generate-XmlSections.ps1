. "$PSScriptRoot\..\Vendor\Logging.ps1"

<#
.SYNOPSIS
    Generates XML fragments for autounattend.xml.

.DESCRIPTION
    Generate-XmlSections is the tenth stage in the autounattend generator
    pipeline. It produces three XML fragments:

        1. Specialize → RunSynchronous
        2. FirstLogonCommands
        3. Active Setup registry entries

    These fragments will later be inserted into the final autounattend.xml.

.PARAMETER Groups
    Hashtable with keys:
        Specialize, FirstLogon, ActiveSetup

.PARAMETER BootstrapScriptPath
    Path to Bootstrap.ps1 on the target machine.

.PARAMETER FirstLogonScriptPath
    Path to FirstLogon.ps1 on the target machine.

.PARAMETER ActiveSetupScriptPath
    Path to ActiveSetup.ps1 on the target machine.

.OUTPUTS
    Hashtable containing:
        SpecializeXml
        FirstLogonXml
        ActiveSetupXml
#>
function Generate-XmlSections {
    param(
        [Parameter(Mandatory)]
        [string] $WorkspacePath,
    
        [Parameter(Mandatory)]
        [string] $SpecializeScriptPath,

        [Parameter(Mandatory)]
        [string] $FirstLogonScriptPath
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Generating XML sections for unattend template")

    #
    # 1. Specialize → RunSynchronous
    #
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Building Specialize XML section using specialize script '$SpecializeScriptPath'")
    $specializeXml = @"
<RunSynchronousCommand wcm:action="add">
<Order>3</Order>
<Path>powershell.exe -ExecutionPolicy Bypass -File "$SpecializeScriptPath"</Path>
</RunSynchronousCommand>
"@

    #
    # 2. FirstLogonCommands
    #
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Building FirstLogon XML section using script '$FirstLogonScriptPath'")
    $firstLogonXml = @"
<FirstLogonCommands>
  <SynchronousCommand wcm:action="add">
    <Order>1</Order>
    <CommandLine>powershell.exe -ExecutionPolicy Bypass -File "$FirstLogonScriptPath"</CommandLine>
    <Description>FirstLogon</Description>
  </SynchronousCommand>
</FirstLogonCommands>
"@

    Write-Timestamped (Format-Line -Level "INFO" -Message "XML section generation complete")

    return @{
        WorkspacePath  = $WorkspacePath
        SpecializeXml  = $specializeXml
        FirstLogonXml  = $firstLogonXml
    }
}
