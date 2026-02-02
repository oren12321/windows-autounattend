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

    #
    # 1. Specialize → RunSynchronous
    #
    $specializeXml = @"
<RunSynchronous>
  <RunSynchronousCommand wcm:action="add">
    <Order>1</Order>
    <Path>powershell.exe -ExecutionPolicy Bypass -File "$BootstrapScriptPath"</Path>
  </RunSynchronousCommand>
</RunSynchronous>
"@

    #
    # 2. FirstLogonCommands
    #
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
    $activeSetupXml = "<Registry>`r`n"

    $i = 1
    foreach ($cmd in $Groups.ActiveSetup) {
        $key = "HKLM\Software\Microsoft\Active Setup\Installed Components\$($cmd.Project)_$($cmd.Order)"

        $activeSetupXml += @"
  <AddReg>
    <Key>$key</Key>
    <Value Name="StubPath" Type="REG_SZ">powershell.exe -ExecutionPolicy Bypass -File "$ActiveSetupScriptPath"</Value>
  </AddReg>
"@
        $i++
    }

    $activeSetupXml += "</Registry>"

    return @{
        SpecializeXml  = $specializeXml
        FirstLogonXml  = $firstLogonXml
        ActiveSetupXml = $activeSetupXml
    }
}
