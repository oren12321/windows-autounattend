. "$PSScriptRoot\Apply-Registry.ps1"
. "$PSScriptRoot\RegistryPlacement.ps1"

$scripts = @(
    {
        reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"
    };
    {
        . "$PSScriptRoot\ExplorerRegistry.User.ps1"
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $ExplorerEntries -Scope DefaultUser))
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $(Get-WallpaperConfigurationEntries) -Scope DefaultUser))
	};
    {
        . "$PSScriptRoot\PerformanceRegistry.User.ps1"
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $Entries $PerformanceEntries -Scope DefaultUser))
	};
    {
        . "$PSScriptRoot\ShellUIRegistry.User.ps1"
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $ShellUIEntries -Scope DefaultUser))
	};
    {
        . "$PSScriptRoot\SecurityAndPrivacyRegistry.User.ps1"
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $SecurityAndPrivacyEntries -Scope DefaultUser))
	};
    {
        . "$PSScriptRoot\SoundAndNotificationsRegistry.User.ps1"
        Apply-RegistryBatch $(Convert-EntriesToDefaultUserHive $(Get-EntriesForScope -Entries $SoundAndNotificationsEntries -Scope DefaultUser))
	};
    {
        $setup = Get-ItemProperty -Path 'HKLM:\SYSTEM\Setup'

        # Only unload the hive when Windows Setup is NOT running
        if ($setup.SystemSetupInProgress -eq 0 -and $setup.OOBEInProgress -eq 0) {
            reg.exe unload "HKU\DefaultUser"
        }
        else {
            Write-Output "Default user hive should not be unloaded during Windows setup"
        }
    };
);

& {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity "Running scripts to modify the default user$([char]0x2019)$([char]0x2019)s registry hive. Do not close this window." -PercentComplete $complete;
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
} *>&1 | Out-String -Width 1KB -Stream >> "$PSScriptRoot\..\Logs\DefaultUser.log";