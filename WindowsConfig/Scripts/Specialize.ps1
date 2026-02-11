$scripts = @(
    {
        & "$PSScriptRoot\CopyLayoutXml.ps1"
    };
    {
        & "$PSScriptRoot\Debloat.ps1"
    };
    {
        & "$PSScriptRoot\ConfigureSetupAndOOBE.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureSetupAndOOBE.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigurePowerSettings.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigurePowerSettings.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureWindowsUpdate.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureWindowsUpdate.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureWindowsAI.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureWindowsAI.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureSecurityAndPrivacy.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureSecurityAndPrivacy.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigurePerformance.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigurePerformance.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureExplorer.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureExplorer.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureShellUI.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureShellUI.System.log" 2>&1
    };
    {
        & "$PSScriptRoot\ConfigureSoundAndNotifications.System.ps1" >> "$PSScriptRoot\..\Logs\ConfigureSoundAndNotifications.System.log" 2>&1
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
} *>&1 | Out-String -Width 1KB -Stream >> "$PSScriptRoot\..\Logs\Specialize.log";
