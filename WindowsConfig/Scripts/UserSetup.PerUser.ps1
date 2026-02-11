. "$PSScriptRoot\Apply-Registry.ps1"
. "$PSScriptRoot\RegistryPlacement.ps1"

$logsDir = "$env:LOCALAPPDATA\MySetup"
if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
}

$scripts = @(
	{
        . "$PSScriptRoot\ExplorerRegistry.User.ps1"
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $ExplorerEntries -Scope PerUser)
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $(Get-WallpaperConfigurationEntries) -Scope PerUser)
	};
    {
        . "$PSScriptRoot\PerformanceRegistry.User.ps1"
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $Entries $PerformanceEntries -Scope PerUser)
	};
    {
        . "$PSScriptRoot\ShellUIRegistry.User.ps1"
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $ShellUIEntries -Scope PerUser)
	};
    {
        . "$PSScriptRoot\SecurityAndPrivacyRegistry.User.ps1"
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $SecurityAndPrivacyEntries -Scope PerUser)
	};
    {
        . "$PSScriptRoot\SoundAndNotificationsRegistry.User.ps1"
        Apply-RegistryBatch $(Get-EntriesForScope -Entries $SoundAndNotificationsEntries -Scope PerUser)
	};
);

& {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity 'Running scripts to configure this user account. Do not close this window.' -PercentComplete $complete;
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
} *>&1 | Out-String -Width 1KB -Stream >> "$logsDir\UserSetup.PerUser.log";