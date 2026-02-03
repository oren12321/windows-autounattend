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
        [hashtable] $Groups,

        [Parameter(Mandatory)]
        [string] $BootstrapScriptPath,

        [Parameter(Mandatory)]
        [string] $FirstLogonScriptPath,

        [Parameter(Mandatory)]
        [string] $ActiveSetupScriptPath
    )

    Write-Timestamped (Format-Line -Level "INFO" -Message "Generating XML sections for unattend template")

    #
    # 1. Specialize → RunSynchronous
    #
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Building Specialize XML section using bootstrap script '$BootstrapScriptPath'")
    $specializeXml = @"
<RunSynchronous>
  <RunSynchronousCommand wcm:action="add">
    <Order>2</Order>
    <Path>powershell.exe -ExecutionPolicy Bypass -File "$BootstrapScriptPath"</Path>
  </RunSynchronousCommand>
</RunSynchronous>
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

    #
    # 3. Active Setup registry entries
    #
    Write-Timestamped (Format-Line -Level "DEBUG" -Message "Building Active Setup XML section using script '$ActiveSetupScriptPath'")
    $key = "HKLM\Software\Microsoft\Active Setup\Installed Components\Autounattend"
    $activeSetupXml = @"
<Registry>
  <AddReg>
    <Key>$key</Key>
    <Value Name="StubPath" Type="REG_SZ">powershell.exe -ExecutionPolicy Bypass -File "$ActiveSetupScriptPath"</Value>
  </AddReg>
</Registry>
"@

    Write-Timestamped (Format-Line -Level "INFO" -Message "XML section generation complete")

    return @{
        SpecializeXml  = $specializeXml
        FirstLogonXml  = $firstLogonXml
        ActiveSetupXml = $activeSetupXml
    }
}
