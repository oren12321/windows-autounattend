$scripts = @(
    {
        & "C:\MySetup\Scripts\CopyLayoutXml.ps1"
    };
    {
        & "C:\MySetup\Scripts\Debloat.ps1"
    };
    {
        & "C:\MySetup\Scripts\ConfigureSetupAndOOBE.System.ps1" >> "C:\MySetup\Logs\ConfigureSetupAndOOBE.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigurePowerSettings.System.ps1" >> "C:\MySetup\Logs\ConfigurePowerSettings.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureWindowsUpdate.System.ps1" >> "C:\MySetup\Logs\ConfigureWindowsUpdate.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureWindowsAI.System.ps1" >> "C:\MySetup\Logs\ConfigureWindowsAI.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureSecurityAndPrivacy.System.ps1" >> "C:\MySetup\Logs\ConfigureSecurityAndPrivacy.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigurePerformance.System.ps1" >> "C:\MySetup\Logs\ConfigurePerformance.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureExplorer.System.ps1" >> "C:\MySetup\Logs\ConfigureExplorer.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureShellUI.System.ps1" >> "C:\MySetup\Logs\ConfigureShellUI.System.log" 2>&1
    };
    {
        & "C:\MySetup\Scripts\ConfigureSoundAndNotifications.System.ps1" >> "C:\MySetup\Logs\ConfigureSoundAndNotifications.System.log" 2>&1
    };
);

& {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity 'Running scripts to customize your Windows installation. Do not close this window.' -PercentComplete $complete;
    "*** Will now execute command $([char]0xAB){0}$([char]0xBB)." -f $(
      $str = $script.ToString().Trim() -replace '\s+', ' ';
      $max = 100;
      if( $str.Length -le $max ) {
        $str;
      } else {
        $str.Substring( 0, $max - 1 ) + "$([char]0x2026)";
      }
    );
    $start = [datetime]::Now;
    & $script;
    '*** Finished executing command after {0:0} ms.' -f [datetime]::Now.Subtract( $start ).TotalMilliseconds;
    "`r`n" * 3;
    $complete += $increment;
  }
} *>&1 | Out-String -Width 1KB -Stream >> "C:\MySetup\Logs\Specialize.log";
