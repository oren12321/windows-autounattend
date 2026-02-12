<#
  .SYNOPSIS
      Removes Microsoft OneDrive from Windows 10/11 systems.

  .DESCRIPTION
      This script detects and removes Microsoft OneDrive installations including:
      - Registry-based uninstallation using the user's HKU uninstall entry
      - OneDrive files and folders from the current users' AppData folder. (NOTE: Userdata in %USERPROFILE%\OneDrive is preserved)
      - System-wide OneDrive installation files
      - OneDrive scheduled tasks
      - Start Menu shortcuts
      - Default user profile configuration to prevent auto-installation

      This script is designed to run in any context: user sessions, SYSTEM account, or scheduled tasks.

  .NOTES
      Source: https://github.com/memstechtips/Winhance

      Requirements:
      - Windows 10/11
      - Administrator privileges (script will auto-elevate)
      - PowerShell 5.1 or higher
      
      Refined by additional guards to prevent reinstallation
#>

# Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    }
    Catch {
        Write-Information "Failed to run as Administrator. Please rerun with elevated privileges."
        Exit
    }
}

Write-Information "Starting OneDrive removal process"

# Get the interactive user when running as SYSTEM (not needed for regular user execution)
function Get-TargetUser {
    Write-Information "Get-TargetUser: Starting user detection"

    # Try interactive user first
    try {
        $user = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName
        Write-Information "Get-TargetUser: Win32_ComputerSystem returned: '$user'"
        if ($user -and $user -ne "NT AUTHORITY\SYSTEM") {
            $username = $user.Split('\')[1]
            Write-Information "Get-TargetUser: Extracted username: '$username'"
            return $username
        }
        Write-Information "Get-TargetUser: User is null or SYSTEM, trying fallback method"
    }
    catch {
        Write-Information "Get-TargetUser: Win32_ComputerSystem failed: $($_.Exception.Message)"
    }

    # Fallback: find user running explorer.exe
    try {
        $explorer = Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -First 1
        Write-Information "Get-TargetUser: Explorer process found: $($explorer -ne $null)"
        if ($explorer) {
            $owner = $explorer.GetOwner()
            Write-Information "Get-TargetUser: Explorer owner: Domain='$($owner.Domain)', User='$($owner.User)'"
            return $owner.User
        }
        Write-Information "Get-TargetUser: No explorer process found"
    }
    catch {
        Write-Information "Get-TargetUser: Explorer method failed: $($_.Exception.Message)"
    }

    Write-Information "Get-TargetUser: No user found, returning null"
    return $null
}

# Get the user's SID for registry access
function Get-UserSID {
    param($Username)
    try {
        $user = New-Object System.Security.Principal.NTAccount($Username)
        return $user.Translate([System.Security.Principal.SecurityIdentifier]).Value
    }
    catch {
        Write-Information "Get-UserSID: Failed for user '$Username': $($_.Exception.Message)"
        return $null
    }
}

# Determine user profile to check
Write-Information "Current environment: USERNAME='$env:USERNAME', USERPROFILE='$env:USERPROFILE'"

if ($env:USERNAME -eq "SYSTEM" -or $env:USERNAME -like "*$" -or $env:USERPROFILE -like "*\system32\config\systemprofile") {
    Write-Information "Running as SYSTEM, attempting to detect target user"
    $targetUser = Get-TargetUser
    if ($targetUser) {
        $userProfilePath = "C:\Users\$targetUser"
        Write-Information "Running as SYSTEM, targeting user: '$targetUser', profile path: '$userProfilePath'"
    } else {
        Write-Information "Running as SYSTEM but no target user found"
        $userProfilePath = $null
    }
} else {
    $targetUser = $env:USERNAME
    $userProfilePath = $env:USERPROFILE
    Write-Information "Running as regular user: '$targetUser', profile path: '$userProfilePath'"
}

# Step 1: Check registry for OneDrive installation and run uninstaller if found
if ($targetUser) {
    $userSID = Get-UserSID -Username $targetUser
    if ($userSID) {
        Write-Information "User SID for '$targetUser': $userSID"

        # Check if OneDrive uninstall entry exists in user's registry
        $uninstallKey = "HKU\$userSID\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
        Write-Information "Checking uninstall registry key: $uninstallKey"

        try {
            # Query the uninstall string
            $uninstallString = reg.exe query $uninstallKey /v UninstallString 2>$null
            if ($LASTEXITCODE -eq 0 -and $uninstallString) {
                # Extract the actual command from reg output
                $uninstallLine = $uninstallString | Where-Object { $_ -match "UninstallString" } | Select-Object -First 1
                if ($uninstallLine -match "REG_SZ\s+(.+)") {
                    $uninstallCommand = $matches[1].Trim()
                    Write-Information "Found uninstall command: $uninstallCommand"

                    # Stop OneDrive processes
                    Write-Information "Stopping OneDrive processes"
                    Stop-Process -Name "*OneDrive*" -Force -ErrorAction SilentlyContinue | Out-Null

                    # Execute the uninstall command directly
                    Write-Information "Executing registry-based uninstaller"

                    if ($uninstallCommand -match '^"([^"]+)"(.*)') {
                        $exePath = $matches[1]
                        $arguments = $matches[2].Trim()
                        Write-Information "Command: '$exePath' Arguments: '$arguments'"
                        Start-Process -FilePath $exePath -ArgumentList $arguments -WindowStyle Hidden -Wait | Out-Null
                    } else {
                        # Fallback: execute as-is
                        Write-Information "Command: '$uninstallCommand'"
                        cmd.exe /c $uninstallCommand 2>&1 | Out-Null
                    }
                    Write-Information "Registry-based uninstaller completed"
                } else {
                    Write-Information "Could not parse UninstallString from registry output"
                }
            } else {
                Write-Information "OneDrive uninstall registry key not found or empty"
            }
        }
        catch {
            Write-Information "Registry-based uninstall failed: $($_.Exception.Message)"
        }
    } else {
        Write-Information "Could not get user SID for '$targetUser'"
    }
} else {
    Write-Information "No target user found for uninstall check"
}

# Step 3: Always run cleanup tasks
Write-Information "Starting cleanup tasks"

# 3.1: Delete OneDrive registry key
if ($targetUser -and $userSID) {
    $uninstallKey = "HKU\$userSID\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
    Write-Information "Deleting OneDrive uninstall registry key: $uninstallKey"
    reg.exe delete $uninstallKey /f 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Information "Registry key deleted successfully"
    } else {
        Write-Information "Registry key not found or already deleted"
    }
}

# 3.2: Delete OneDrive AppData folder
if ($userProfilePath) {
    $currentUserOneDrivePath = Join-Path $userProfilePath "AppData\Local\Microsoft\OneDrive"
    Write-Information "Checking OneDrive AppData folder: $currentUserOneDrivePath"

    if (Test-Path $currentUserOneDrivePath) {
        Write-Information "Removing OneDrive folder for user: $targetUser"
        try {
            takeown /f $currentUserOneDrivePath /r /d y 2>&1 | Out-Null
            icacls $currentUserOneDrivePath /grant "${env:USERNAME}:F" /t 2>&1 | Out-Null
            Remove-Item $currentUserOneDrivePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Information "OneDrive folder removed for user: $targetUser"
        }
        catch {
            Write-Information "Failed to remove OneDrive folder for user: $targetUser - $($_.Exception.Message)"
        }
    } else {
        Write-Information "OneDrive AppData folder not found"
    }
}

# 3.3: Delete OneDrive Start Menu entry
if ($userProfilePath) {
    $startMenuPath = Join-Path $userProfilePath "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    Write-Information "Checking OneDrive Start Menu shortcut: $startMenuPath"

    if (Test-Path $startMenuPath) {
        Remove-Item $startMenuPath -Force -ErrorAction SilentlyContinue
        Write-Information "OneDrive Start Menu shortcut removed"
    } else {
        Write-Information "OneDrive Start Menu shortcut not found"
    }
}

# 3.4: Delete system OneDrive files
$systemPaths = @(
    "C:\Windows\System32\OneDriveSetup.exe",
    "C:\Windows\SysWOW64\OneDriveSetup.exe",
    "C:\Program Files\Microsoft OneDrive"
)

foreach ($path in $systemPaths) {
    Write-Information "Checking system path: $path"
    if (Test-Path $path) {
        Write-Information "Removing: $path"
        try {
            takeown /f $path /r /d y 2>&1 | Out-Null
            icacls $path /grant "${env:USERNAME}:F" /t 2>&1 | Out-Null
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Information "Successfully removed: $path"
        }
        catch {
            Write-Information "Failed to remove: $path - $($_.Exception.Message)"
        }
    } else {
        Write-Information "Path not found: $path"
    }
}

# 3.5: Delete OneDrive scheduled tasks
Write-Information "Checking for OneDrive scheduled tasks"
try {
    $oneDriveTasks = Get-ScheduledTask -TaskName "*OneDrive*" -ErrorAction SilentlyContinue
    if ($oneDriveTasks) {
        foreach ($task in $oneDriveTasks) {
            # Skip the OneDriveRemoval task
            if ($task.TaskName -eq "OneDriveRemoval") {
                Write-Information "Skipping OneDriveRemoval task: $($task.TaskName)"
                continue
            }
            
            Write-Information "Found OneDrive scheduled task: $($task.TaskName) - State: $($task.State)"
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
                Write-Information "Deleted scheduled task: $($task.TaskName)"
            }
            catch {
                Write-Information "Failed to delete scheduled task: $($task.TaskName) - $($_.Exception.Message)"
            }
        }
    } else {
        Write-Information "No OneDrive scheduled tasks found"
    }
}
catch {
    Write-Information "Failed to check scheduled tasks: $($_.Exception.Message)"
}

# 3.6: Configure default user registry to prevent OneDrive auto-install
$markerKey = "HKLM\SOFTWARE\Winhance\OneDriveRemoval"
$markerValue = reg.exe query $markerKey /v "DefaultUserConfigured" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Information "Default user already configured on this machine, skipping this step."
} else {
    Write-Information "Configuring registry to prevent OneDrive auto-install for new users"
    reg.exe Load HKEY_USERS\Default "C:\Users\Default\NTUSER.DAT" 2>&1 | Out-Null
    reg.exe delete "HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f 2>&1 | Out-Null
    reg.exe add "HKU\Default\SOFTWARE\Microsoft\OneDrive" /v "EnableTHDFFeatures" /t REG_DWORD /d "0" /f 2>&1 | Out-Null
    # Close regedit in case it is running so we can unload the hive
    Stop-Process -Name "regedit" -Force -ErrorAction SilentlyContinue
    reg.exe Unload HKEY_USERS\Default 2>&1 | Out-Null

    # Create marker to indicate this machine has been configured
    reg.exe add $markerKey /v "DefaultUserConfigured" /t REG_SZ /d "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" /f 2>&1 | Out-Null
    Write-Information "Default user configuration completed and marked"
}

# 1. Create the Appx Deprovisioned Marker
$OneDrivePFN = "Microsoft.OneDrive_8wekyb3d8bbwe"
$DeprovisionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$OneDrivePFN"
if (!(Test-Path $DeprovisionPath)) { New-Item -Path $DeprovisionPath -Force }

# 2. Block the legacy system-wide installer via Policy
# This is the "Gold Standard" for 2025 to stop the .exe from returning
$PolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (!(Test-Path $PolicyPath)) { New-Item -Path $PolicyPath -Force }
New-ItemProperty -Path $PolicyPath -Name "DisableFileSyncNGSC" -Value 1 -PropertyType DWORD -Force

Write-Information "Done."