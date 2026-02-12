<#
  .SYNOPSIS
      Removes Microsoft Edge (Legacy and Chromium versions) from Windows 10/11 systems.

  .DESCRIPTION
      This script detects and removes Microsoft Edge installations including:
      - Legacy UWP Edge (pre-Chromium)
      - Chromium-based Edge (current version)
      - EdgeUpdate components
      - EdgeWebView2 is NOT removed

      This script is designed to run in any context: user sessions, SYSTEM account, or scheduled tasks.

  .NOTES
      Source: https://github.com/memstechtips/Winhance

      Requirements:
      - Windows 10/11
      - Administrator privileges (script will auto-elevate)
      - PowerShell 5.1 or higher

      Credits:
      - Legacy Edge removal based on work by ishad0w: https://gist.github.com/ishad0w/d25ca52eb04dbefba8087a344a69c79c
      - Chromium Edge removal based on work by FR33THY: https://github.com/FR33THYFR33THY/Ultimate-Windows-Optimization-Guide/blob/main/6%20Windows/14%20Edge.ps1
      - Edge protocol redirect based on OpenWebSearch by AveYo: https://github.com/AveYo/fox/blob/main/OpenWebSearch.cmd
      
      Minor refactoring for embedding in Schneegans's generated autounattend.xml
#>

# Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    }
    Catch {
        Write-Output "Failed to run as Administrator. Please rerun with elevated privileges."
        Exit
    }
}

# Helper function to get Legacy Edge packages
function Get-LegacyEdgePackages {
    $legacyRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
    return Get-ChildItem -Path $legacyRegPath -Name -ErrorAction SilentlyContinue | Where-Object { $_ -match "Microsoft-Windows-Internet-Browser-Package" -and $_ -match "~~" }
}

# Function to test if Legacy Edge is installed
function Test-LegacyEdgeInstalled {
    $packages = Get-LegacyEdgePackages

    if ($packages) {
        foreach ($package in $packages) {
            $packageInfo = & dism /online /Get-PackageInfo /PackageName:$package 2>$null
            if ($packageInfo -match "State.*Installed") {
                return $true
            }
        }
    }
    return $false
}

# Function to test if Chromium Edge is installed
function Test-ChromiumEdgeInstalled {
    # Check folders first (fastest)
    $edgeFolders = @("Edge", "EdgeCore", "EdgeUpdate")
    $programFiles = @($env:ProgramFiles, ${env:ProgramFiles(x86)})

    foreach ($pf in $programFiles) {
        foreach ($folder in $edgeFolders) {
            if (Test-Path "$pf\Microsoft\$folder") {
                return $true
            }
        }
    }

    # Fallback: Check installed programs
    try {
        $edgeApp = Get-WmiObject -Class Win32_InstalledStoreProgram -Filter "Name like '%Microsoft.MicrosoftEdge.Stable%'" -ErrorAction SilentlyContinue
        return $edgeApp -ne $null
    } catch {
        return $false
    }
}

# Function to stop Edge-related processes
function Stop-EdgeProcesses {
    Write-Output "Stopping Edge-related processes and services"
    $stop = "MicrosoftEdgeUpdate", "OneDrive", "WidgetService", "Widgets", "msedge", "Resume", "CrossDeviceResume", "msedgewebview2"
    $stop | ForEach-Object {
        $processCount = (Get-Process -Name $_ -ErrorAction SilentlyContinue).Count
        if ($processCount -gt 0) {
            Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
            Write-Output "Stopped $processCount instance(s) of $_"
        }
    }
}

# Function to remove Legacy Edge
function Remove-LegacyEdge {
    Write-Output "Starting Legacy Edge/UWP Edge removal process"
    # Query registry for Edge Legacy package
    $packages = Get-LegacyEdgePackages
    $edgeLegacyPackageVersion = $packages | Select-Object -First 1
    $packagePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$edgeLegacyPackageVersion"
    # Set registry visibility
    Set-ItemProperty -Path $packagePath -Name "Visibility" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    # Remove owners registry entries
    $ownersPath = "$packagePath\Owners"
    if (Test-Path $ownersPath) { Remove-Item -Path $ownersPath -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Output "Removing Legacy Edge package via DISM (with 30-second timeout)"
    $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/online", "/Remove-Package", "/PackageName:$edgeLegacyPackageVersion", "/NoRestart" -NoNewWindow -PassThru

    if ($dismProcess -and $dismProcess.WaitForExit(30000)) {
        Write-Output "DISM completed successfully"
    } elseif ($dismProcess) {
        Write-Output "DISM timed out after 30 seconds, killing process and retrying once"
        $dismProcess.Kill()
        Start-Sleep 2

        # Retry once
        Write-Output "Retrying DISM command"
        $retryProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/online", "/Remove-Package", "/PackageName:$edgeLegacyPackageVersion", "/NoRestart" -NoNewWindow -PassThru

        if ($retryProcess -and $retryProcess.WaitForExit(30000)) {
            Write-Output "DISM retry completed successfully"
        } elseif ($retryProcess) {
            Write-Output "DISM retry also timed out, continuing with script"
            $retryProcess.Kill()
        } else {
            Write-Output "DISM retry failed to start, continuing with script"
        }
    } else {
        Write-Output "DISM failed to start, continuing with script"
    }
    # Remove Legacy UWP Edge package
    Write-Output "Removing Legacy UWP Edge package"
    Get-AppxPackage Microsoft.MicrosoftEdge | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
    Write-Output "Legacy Edge/UWP Edge removal process completed"
}

# Function to remove Edge shortcuts
function Remove-EdgeShortcuts {
    Write-Output "Starting Edge shortcuts cleanup"

    # Get ALL user profiles (no exclusions)
    $userProfiles = Get-ChildItem -Path "C:\Users" -Directory | Where-Object {
        (Test-Path -Path "$($_.FullName)\NTUSER.DAT")
    }

    # Build all shortcut paths to check
    $shortcutPaths = @()

    # Add user-specific paths (now includes Public, Default, etc.)
    foreach ($profile in $userProfiles) {
        $shortcutPaths += @(
            "$($profile.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk",
            "$($profile.FullName)\Desktop\Microsoft Edge.lnk",
            "$($profile.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk",
            "$($profile.FullName)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk",
            "$($profile.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
        )
    }

    # Add the single ProgramData path
    $shortcutPaths += "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

    # Remove all shortcuts in one loop
    $removedCount = 0
    foreach ($path in $shortcutPaths) {
        if (Test-Path -Path $path -PathType Leaf) {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }

    Write-Output "Removed $removedCount Edge shortcut(s)"
}

function Install-EdgeProtocolRedirect {
    Write-Output "Checking if Edge protocol redirect is needed"

    $ifeoCheck = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe\0"
    if (Test-Path $ifeoCheck) {
        $debugger = (Get-ItemProperty -Path $ifeoCheck -Name "Debugger" -ErrorAction SilentlyContinue).Debugger
        if ($debugger -like "*OpenWebSearch*") {
            Write-Output "Edge protocol redirect already installed"
            return
        }
    }

    Write-Output "Installing Edge protocol redirect using OpenWebSearch"
    $scriptsDir = "C:\MySetup\Scripts\OpenWebSearch"
    New-Item -ItemType Directory -Path $scriptsDir -Force -ErrorAction SilentlyContinue | Out-Null

    $stubTargetPath = "$scriptsDir\ie_to_edge_stub.exe"
    if (!(Test-Path $stubTargetPath)) {
        Write-Output "Warning: ie_to_edge_stub.exe not found at $stubTargetPath (should have been copied before Edge removal)"
        return
    }

    $openWebSearchContent = @"
@title OpenWebSearch 2023 & echo off
for /f %%E in ('"prompt `$E`$S& for %%e in (1) do rem"') do echo;%%E[2t 2>nul

call :reg_var "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID ProgID
if /i "%ProgID%" equ "MSEdgeHTM" exit /b

call :reg_var "HKCR\%ProgID%\shell\open\command" "" Browser
set Choice=& for %%. in (%Browser%) do if not defined Choice set "Choice=%%~."

call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set "Edge=" & for %%. in (%FallBack%) do if not defined Edge set "Edge=%%~."
set "URI=" & set "URL=" & set "NOOP=" & set "PassTrough=%Edge:msedge=edge%"

set "CLI=%CMDCMDLINE:"=````%"
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe```` =%"
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe =%"
if defined CLI set "CLI=%CLI:*msedge.exe```` =%"
if defined CLI set "CLI=%CLI:*msedge.exe =%"
set "FIX=%CLI:~-1%"
if defined CLI if "%FIX%"==" " set "CLI=%CLI:~0,-1%"
if defined CLI set "RED=%CLI:microsoft-edge=%"
if defined CLI set "URL=%CLI:http=%"
if defined CLI set "ARG=%CLI:````="%"

if "%CLI%" equ "%RED%" (set NOOP=1) else if "%CLI%" equ "%URL%" (set NOOP=1)
if defined NOOP if not exist "%PassTrough%" echo;@mklink /h "%PassTrough%" "%Edge%" >"%Temp%\OpenWebSearchRepair.cmd"
if defined NOOP if not exist "%PassTrough%" schtasks /run /tn OpenWebSearchRepair 2>nul >nul
if defined NOOP if not exist "%PassTrough%" timeout /t 3 >nul
if defined NOOP if exist "%PassTrough%" start "" "%PassTrough%" %ARG%
if defined NOOP exit /b

set "URL=%CLI:*microsoft-edge=%"
set "URL=http%URL:*http=%"
set "FIX=%URL:~-2%"
if defined URL if "%FIX%"=="````" set "URL=%URL:~0,-2%"
call :dec_url
start "" "%Choice%" "%URL%"
exit

:reg_var
set {var}=& set {reg}=reg query "%~1" /v %2 /z /se "," /f /e& if %2=="" set {reg}=reg query "%~1" /ve /z /se "," /f /e
for /f "skip=2 tokens=* delims=" %%V in ('%{reg}% %4 %5 %6 %7 %8 %9 2^>nul') do if not defined {var} set "{var}=%%V"
if not defined {var} (set {reg}=& set "%~3="& exit /b) else if %2=="" set "{var}=%{var}:*)    =%"
if not defined {var} (set {reg}=& set "%~3="& exit /b) else set {reg}=& set "%~3=%{var}:*)    =%"& set {var}=& exit /b

:dec_url
set ".=%URL:!=}%" & setlocal enabledelayedexpansion
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=`$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%%!"&set ".=!.:{20= !"
set ".=!.:{=%%!" & endlocal& set "URL=%.:}=!%" & exit /b
"@

    $openWebSearchPath = "$scriptsDir\OpenWebSearch.cmd"
    $openWebSearchContent | Out-File -FilePath $openWebSearchPath -Encoding ASCII -Force
    Write-Output "Created OpenWebSearch.cmd at $openWebSearchPath"

    $msedgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\edge.exe"
    if ((Test-Path $msedgePath) -and !(Test-Path $edgePath)) {
        cmd /c mklink /h "$edgePath" "$msedgePath" 2>&1 | Out-Null
        Write-Output "Created edge.exe hardlink at $edgePath"
    }

    $buildNumber = [Environment]::OSVersion.Version.Build
    $conhostFlags = if ($buildNumber -gt 25179) { "--width 1 --height 1" } else { "--headless" }
    $conhostDebugger = "$env:SystemRoot\system32\conhost.exe $conhostFlags $scriptsDir\OpenWebSearch.cmd"

    Write-Output "Configuring registry entries for Edge protocol redirect"
    reg.exe add "HKCR\microsoft-edge" /f /ve /d "URL:microsoft-edge" 2>&1 | Out-Null
    reg.exe add "HKCR\microsoft-edge" /f /v "URL Protocol" /d `"`" 2>&1 | Out-Null
    reg.exe add "HKCR\microsoft-edge" /f /v "NoOpenWith" /d `"`" 2>&1 | Out-Null
    reg.exe add "HKCR\microsoft-edge\shell\open\command" /f /ve /d "$stubTargetPath %1" 2>&1 | Out-Null
    reg.exe add "HKCR\MSEdgeHTM" /f /v "NoOpenWith" /d `"`" 2>&1 | Out-Null
    reg.exe add "HKCR\MSEdgeHTM\shell\open\command" /f /ve /d "$stubTargetPath %1" 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe" /f /v UseFilter /d 1 /t reg_dword 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe\0" /f /v FilterFullPath /d "$stubTargetPath" 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe\0" /f /v Debugger /d "$conhostDebugger" 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe" /f /v UseFilter /d 1 /t reg_dword 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe\0" /f /v FilterFullPath /d "$msedgePath" 2>&1 | Out-Null
    reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe\0" /f /v Debugger /d "$conhostDebugger" 2>&1 | Out-Null
    Write-Output "Registry configuration completed"

    $repairScriptPath = "$scriptsDir\OpenWebSearchRepair.cmd"
    $repairScriptContent = "@echo off`r`nmklink /h ""$edgePath"" ""$msedgePath"""
    $repairScriptContent | Out-File -FilePath $repairScriptPath -Encoding ASCII -Force
    Write-Output "Created repair script at $repairScriptPath"

    Write-Output "Creating OpenWebSearchRepair scheduled task"
    try {
        $taskAction = New-ScheduledTaskAction -Execute $repairScriptPath
        $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId "S-1-5-18" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName 'OpenWebSearchRepair' -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Force | Out-Null
        Write-Output "OpenWebSearchRepair scheduled task created"
    } catch {
        Write-Output "Failed to create OpenWebSearchRepair scheduled task: $($_.Exception.Message)"
    }
}

# Function to remove Chromium Edge and EdgeUpdate
function Remove-ChromiumEdge {
    # Remove Chromium Edge
    Write-Output "Starting Edge Chromium uninstallation process"
    # Folder and file to allow uninstall of Edge Chromium Browser
    Write-Output "Creating temporary directory for Edge uninstallation"
    $edgePath = "$env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    New-Item -Path $edgePath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path $edgePath -ItemType File -Name "MicrosoftEdge.exe" -ErrorAction SilentlyContinue | Out-Null
    # Get Edge Uninstall Strings for Enterprise MSI version or normal version (they require different handling)
    Write-Output "Searching for Edge uninstall strings in registry"
    $uninstallKeys = Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $edgeUninstallCount = 0
    foreach ($key in $uninstallKeys) {
        $displayName = (Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue).DisplayName
        if ($displayName -like "*Microsoft Edge*") {
            $uninstallString = (Get-ItemProperty $key.PSPath).UninstallString
            if ($uninstallString) {
                $edgeUninstallCount++
                if ($uninstallString -like "*msiexec*") {
                    # Uninstalls Enterprise MSI version
                    Write-Output "Executing MSI uninstaller for Edge"
                    Start-Process cmd.exe "/c $uninstallString /quiet" -WindowStyle Hidden -Wait | Out-Null
                } else {
                    # Uninstalls normal version
                    Write-Output "Executing standard uninstaller for Edge"
                    Start-Process cmd.exe "/c $uninstallString --force-uninstall --silent" -WindowStyle Hidden -Wait | Out-Null
                }
            }
        }
    }
    if ($edgeUninstallCount -eq 0) {
        Write-Output "No Edge uninstall entries found in registry"
    } else {
        Write-Output "Executed $edgeUninstallCount Edge uninstaller(s)"
    }
    # Remove UWP Edge Chromium package
    Write-Output "Removing UWP Edge Chromium package"
    Get-AppxPackage *Microsoft.MicrosoftEdge.Stable* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
    # Cleanup: Remove folder and file we created earlier
    Write-Output "Cleaning up temporary Edge directory"
    Remove-Item -Recurse -Force $edgePath -ErrorAction SilentlyContinue | Out-Null
    Write-Output "Edge Chromium uninstallation process completed"

    # Remove EdgeUpdate
    Write-Output "Starting EdgeUpdate removal process"
    # Find EdgeUpdate executables
    Write-Output "Searching for EdgeUpdate executables"
    $edgeupdate = @()
    $searchPaths = @("LocalApplicationData", "ProgramFilesX86", "ProgramFiles")
    foreach ($pathType in $searchPaths) {
        $folder = [Environment]::GetFolderPath($pathType)
        $searchPattern = "$folder\Microsoft\EdgeUpdate\*.*.*.*\MicrosoftEdgeUpdate.exe"
        $foundFiles = Get-ChildItem $searchPattern -Recurse -ErrorAction SilentlyContinue
        if ($foundFiles) {
            $edgeupdate += $foundFiles.FullName
        }
    }
    if ($edgeupdate.Count -gt 0) {
        Write-Output "Found $($edgeupdate.Count) EdgeUpdate executable(s)"
    } else {
        Write-Output "No EdgeUpdate executables found"
    }
    # Backup ClientState registry if it exists (important, or else webview won't work)
    $backupRegFile = "$env:TEMP\EdgeUpdate_ClientState_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    $clientStatePath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\ClientState"
    if (Test-Path $clientStatePath) {
        Write-Output "Backing up EdgeUpdate ClientState registry"
        cmd /c "reg export `"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\ClientState`" `"$backupRegFile`" /y" 2>$null
        if (Test-Path $backupRegFile) {
            Write-Output "Successfully created registry backup at $backupRegFile"
        } else {
            Write-Output "Warning: Failed to create registry backup"
        }
    } else {
        Write-Output "No EdgeUpdate ClientState registry found to backup"
    }
    # Clean registry entries
    Write-Output "Removing EdgeUpdate registry entries"
    $registryPaths = @(
        "HKLM:\SOFTWARE", "HKLM:\SOFTWARE\Policies", "HKLM:\SOFTWARE\WOW6432Node", "HKLM:\SOFTWARE\WOW6432Node\Policies"
    )
    $removedRegCount = 0
    foreach ($location in $registryPaths) {
        $regPath = "$location\Microsoft\EdgeUpdate"
        if (Test-Path $regPath) {
            Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
            $removedRegCount++
        }
    }
    Write-Output "Removed EdgeUpdate registry entries from $removedRegCount location(s)"
    # Uninstall EdgeUpdate executables
    Write-Output "Processing EdgeUpdate uninstallation"
    foreach ($path in $edgeupdate) {
        if (Test-Path $path) {
            # Unregister service
            Write-Output "Unregistering EdgeUpdate service from $path"
            Start-Process -FilePath $path -ArgumentList "/unregsvc" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            # Wait for processes to finish
            $waitCount = 0
            do {
                Start-Sleep 3
                $runningProcesses = Get-Process -Name "setup", "MicrosoftEdge*" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*\Microsoft\Edge*" }
            } while ($runningProcesses -and $waitCount++ -lt 20)
            # Run uninstall if file still exists
            if (Test-Path $path) {
                Write-Output "Running EdgeUpdate uninstaller from $path"
                Start-Process -FilePath $path -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }
    }
    # Restore ClientState backup
    if ((Test-Path $backupRegFile)) {
        Write-Output "Restoring EdgeUpdate ClientState registry from backup"
        cmd /c "reg import `"$backupRegFile`"" 2>$null
        Remove-Item $backupRegFile -ErrorAction SilentlyContinue
        Write-Output "Registry restore completed and backup file cleaned up"
    } else {
        Write-Output "No registry backup file found to restore"
    }
    Write-Output "EdgeUpdate removal process completed"
}

Write-Output "Starting Edge removal process."

# Check for Edge installations first
Write-Output "Checking for Edge installations..."

$legacyInstalled = Test-LegacyEdgeInstalled
$chromiumInstalled = Test-ChromiumEdgeInstalled

if (-not $legacyInstalled -and -not $chromiumInstalled) {
    Write-Output "No Edge installations detected. Exiting."
    Write-Output "No Edge installations found. Script exiting."
    exit 0
}

$removedSomething = $false
$stubPath = $null

if ($chromiumInstalled) {
    Write-Output "Chromium Edge detected. Finding ie_to_edge_stub.exe before removal."

    $stubLocations = @("$env:ProgramData\ie_to_edge_stub.exe", "$env:Public\ie_to_edge_stub.exe")
    foreach ($loc in $stubLocations) {
        if (Test-Path $loc) {
            $stubPath = $loc
            Write-Output "Found stub at: $loc"
            break
        }
    }

    if (!$stubPath) {
        $stubSearch = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft\Edge" -Filter "ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($stubSearch) {
            $stubPath = $stubSearch.FullName
            Write-Output "Found stub at: $stubPath"
        } else {
            Write-Output "ie_to_edge_stub.exe not found in any location"
        }
    }

    if ($stubPath) {
        $scriptsDir = "C:\MySetup\Scripts\OpenWebSearch"
        New-Item -ItemType Directory -Path $scriptsDir -Force -ErrorAction SilentlyContinue | Out-Null
        Copy-Item $stubPath "$scriptsDir\ie_to_edge_stub.exe" -Force -ErrorAction SilentlyContinue
        Write-Output "Copied ie_to_edge_stub.exe to $scriptsDir before Edge removal"
    }
}

if ($legacyInstalled) {
    Write-Output "Legacy Edge detected. Proceeding with removal."
    Stop-EdgeProcesses
    Remove-LegacyEdge
    $removedSomething = $true
}

if ($chromiumInstalled) {
    Write-Output "Chromium Edge detected. Proceeding with removal."
    Stop-EdgeProcesses
    Remove-ChromiumEdge
    $removedSomething = $true
}

# Only do cleanup if we removed something
if ($removedSomething) {
    # Cleanup: Remove folders containing Edge (Edge, EdgeCore, EdgeUpdate) or Temp but exclude EdgeWebView
    Write-Output "Starting cleanup of Microsoft Edge folders"
    $edgeFolders = Get-ChildItem -Path "$env:SystemDrive\Program Files (x86)\Microsoft" -Directory -ErrorAction SilentlyContinue |
    Where-Object { ($_.Name -like "*Edge*" -or $_.Name -like "*Temp*") -and $_.Name -notlike "*EdgeWebView*" }
    if ($edgeFolders) {
        Write-Output "Found $($edgeFolders.Count) Edge-related folder(s) to remove"
        $edgeFolders | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Cleanup of Microsoft Edge folders completed"
    } else {
        Write-Output "No Edge-related folders found to clean up"
    }

    Remove-EdgeShortcuts
    Install-EdgeProtocolRedirect
}

# Always check for and delete Edge scheduled tasks
Write-Output "Checking for Edge scheduled tasks"
try {
    $edgeTasks = Get-ScheduledTask -TaskName "*Edge*" -ErrorAction SilentlyContinue
    if ($edgeTasks) {
        foreach ($task in $edgeTasks) {
            # Skip the EdgeRemoval task
            if ($task.TaskName -eq "EdgeRemoval") {
                Write-Output "Skipping EdgeRemoval task: $($task.TaskName)"
                continue
            }
            
            Write-Output "Found Edge scheduled task: $($task.TaskName) - State: $($task.State)"
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
                Write-Output "Deleted scheduled task: $($task.TaskName)"
            }
            catch {
                Write-Output "Failed to delete scheduled task: $($task.TaskName) - $($_.Exception.Message)"
            }
        }
    } else {
        Write-Output "No Edge scheduled tasks found"
    }
}
catch {
    Write-Output "Failed to check scheduled tasks: $($_.Exception.Message)"
}

Write-Output "Create the EdgeUpdate key and block automatic Chromium Edge installation"
$RegPath = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }
New-ItemProperty -Path $RegPath -Name "DoNotUpdateToEdgeWithChromium" -Value 1 -PropertyType DWORD -Force

Write-Output "Prevent Edge installation via standard Update policies"
$PolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
if (!(Test-Path $PolicyPath)) { New-Item -Path $PolicyPath -Force }
New-ItemProperty -Path $PolicyPath -Name "InstallDefault" -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path $PolicyPath -Name "Install{56EB18F8-8008-4CBD-B6D0-588447950844}" -Value 0 -PropertyType DWORD -Force

Write-Output "Put Package Family Names (PFN) for both Chromium and Legacy Edge in provisioned list"
$EdgePFNs = @(
    "Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe", # Modern Chromium Edge
    "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"         # Legacy Edge
)

foreach ($PFN in $EdgePFNs) {
    $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$PFN"
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Output "Deprovisioned marker added for: $PFN"
    }
}

Write-Output "Done."
