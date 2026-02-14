$selectors = @(
	'Microsoft.Microsoft3DViewer';
	'Microsoft.BingSearch';
	'Clipchamp.Clipchamp';
	'Microsoft.Copilot';
	'Microsoft.549981C3F5F10';
	'Microsoft.Windows.DevHome';
	'MicrosoftCorporationII.MicrosoftFamily';
	'Microsoft.WindowsFeedbackHub';
	'Microsoft.Edge.GameAssist';
	'Microsoft.GetHelp';
	'Microsoft.Getstarted';
	'microsoft.windowscommunicationsapps';
	'Microsoft.WindowsMaps';
	'Microsoft.MixedReality.Portal';
	'Microsoft.BingNews';
	'Microsoft.MicrosoftOfficeHub';
	'Microsoft.Office.OneNote';
	'Microsoft.OutlookForWindows';
	'Microsoft.MSPaint';
	'Microsoft.People';
	'Microsoft.PowerAutomateDesktop';
	'MicrosoftCorporationII.QuickAssist';
	'Microsoft.SkypeApp';
	'Microsoft.MicrosoftSolitaireCollection';
	'Microsoft.MicrosoftStickyNotes';
	'MicrosoftTeams';
	'MSTeams';
	'Microsoft.Todos';
	'Microsoft.Wallet';
	'Microsoft.BingWeather';
	'Microsoft.Xbox.TCUI';
	'Microsoft.XboxApp';
	'Microsoft.XboxGameOverlay';
	'Microsoft.XboxGamingOverlay';
	'Microsoft.XboxIdentityProvider';
	'Microsoft.XboxSpeechToTextOverlay';
	'Microsoft.GamingApp';
	'Microsoft.YourPhone';
	'Microsoft.ZuneVideo';
    'Microsoft.Windows.Ai.Copilot.Provider';
    
    'Microsoft.WindowsStore';
    'Microsoft.StorePurchaseApp';
);
$getCommand = {
  Get-AppxProvisionedPackage -Online;
};
$filterCommand = {
  $_.DisplayName -like "*$selector*";
};
$removeCommand = {
  [CmdletBinding()]
  param(
    [Parameter( Mandatory, ValueFromPipeline )]
    $InputObject
  );
  process {
    $InputObject | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue';
    
    $PFN = (Get-AppxPackage -Name $InputObject.DisplayName -AllUsers).PackageFamilyName

    if ($PFN) {
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$PFN"
        if (!(Test-Path $RegPath)) {
            # Use | Out-Null to prevent this from being captured by $result.Output
            New-Item -Path $RegPath -Force | Out-Null
        }
    }
  }
};
$type = 'Package';
$logfile = "$PSScriptRoot\..\Logs\RemovePackages.log";
& {
	$installed = & $getCommand;
	foreach( $selector in $selectors ) {
		$result = [ordered] @{
			Selector = $selector;
		};
		$found = $installed | Where-Object -FilterScript $filterCommand;
		if( $found ) {
			$result.Output = $found | & $removeCommand;
			if( $? ) {
				$result.Message = "$type removed.";
			} else {
				$result.Message = "$type not removed.";
				$result.Error = $Error[0];
			}
		} else {
			$result.Message = "$type not installed.";
		}
		$result | ConvertTo-Json -Depth 3 -Compress;
	}
    
    # ---------------------------------------------------------
    # INSERTED HERE — inside inline script, so it logs properly
    # ---------------------------------------------------------

    $policyResult = [ordered] @{
        Action = "Apply Store Removal Policies";
    };

    try {
        # Ensure policy key exists
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Force | Out-Null

        # Prevent Store from reinstalling
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" `
                         -Name "RemoveWindowsStore" -Type DWord -Value 1

        # Disable Store auto-downloads
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" `
                         -Name "AutoDownload" -Type DWord -Value 2

        $policyResult.Message = "Policies applied successfully."
    }
    catch {
        $policyResult.Message = "Failed to apply policies."
        $policyResult.Error = $_
    }

    $policyResult | ConvertTo-Json -Depth 3 -Compress

} *>&1 | Out-String -Width 1KB -Stream >> $logfile;
