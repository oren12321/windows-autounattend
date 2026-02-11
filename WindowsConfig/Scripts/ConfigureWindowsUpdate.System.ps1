. "$PSScriptRoot\Apply-Registry.ps1"

$entries = @(
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Name = "AUOptions"
        Type = "DWord"
        Value = 4
        Description="Control how automatic updates behave"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        Name = "DODownloadMode"
        Type = "DWord"
        Value = 99
        Description="Share downloaded updates with other PCs on your network or the internet to reduce bandwidth usage"
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        Name = "IsContinuousInnovationOptedIn"
        Type = "DWord"
        Value = 0
        Description="Be among the first to get the latest non-security updates, fixes, and improvements as they roll out"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "AllowMUUpdateService"
        Type = "DWord"
        Value = 0
        Description="Get Microsoft Office and other updates together with Windows updates"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "IsExpedited"
        Type = "DWord"
        Value = 0
        Description="Restart as soon as possible (even during active hours) to finish updating"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Name = "NoAutoRebootWithLoggedOnUsers"
        Type = "DWord"
        Value = 1
        Description="Prevents automatic restarts after installing updates when users are logged on"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name = "SetUpdateNotificationLevel"
        Type = "DWord"
        Value = 1
        Description="Show or hide notifications about available updates and update progress"
    },
    @{
        Path = "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings"
        Name = "RestartNotificationsAllowed2"
        Type = "DWord"
        Value = 0
        Description="Show notification when your device requires a restart to finish updating"
    },
    @{
        Path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        Name = "AllowAutoWindowsUpdateDownloadOverMeteredNetwork"
        Type = "DWord"
        Value = 0
        Description="Allow Windows to download updates when using mobile hotspots or data-limited connections"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name = "ExcludeWUDriversInQualityUpdate"
        Type = "DWord"
        Value = 1
        Description="Prevent Windows from automatically downloading and installing hardware driver updates"
    },
    @{
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        Name = "AutoDownload"
        Type = "DWord"
        Value = 2
        Description="Automatically download and install updates for apps from the Microsoft Store"
    },
    @{
        Path        = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        Name        = "DisableAutomaticRestartSignOn"
        Type        = "DWord"
        Value       = 1
        Description = "Disable automatic restart sign-on after updates"
    }
)
Apply-RegistryBatch $entries

$pauseUpdateXml = @"
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-01-01T12:00:00-08:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>true</WakeToRun>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT5M</Interval>
      <Count>5</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-ExecutionPolicy "Unrestricted" -NoProfile -File "$PSScriptRoot\PauseWindowsUpdate.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
Register-ScheduledTask -TaskName 'PauseWindowsUpdate' -Xml "$pauseUpdateXml";

$moveHoursPrimary = @"
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
    <CalendarTrigger>
      <StartBoundary>2026-01-01T00:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>PT4H</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT5M</Interval>
      <Count>5</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>"C:\Windows\System32\wscript.exe '$PSScriptRoot\MoveActiveHours.vbs' | Out-File '$PSScriptRoot\..\Logs\MoveActiveHours.log' -Append"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
Register-ScheduledTask -TaskName 'MoveActiveHoursPrimary' -Xml "$moveHoursPrimary";

$moveHoursBackup = @"
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
    <CalendarTrigger>
      <StartBoundary>2026-01-01T00:05:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>PT8H</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>true</WakeToRun>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT5M</Interval>
      <Count>5</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>"C:\Windows\System32\wscript.exe '$PSScriptRoot\MoveActiveHours.vbs' | Out-File '$PSScriptRoot\..\Logs\MoveActiveHours.log' -Append"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
Register-ScheduledTask -TaskName 'MoveActiveHoursBackup' -Xml "$moveHoursBackup";
