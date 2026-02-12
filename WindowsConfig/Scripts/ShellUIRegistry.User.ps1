$ShellUIEntries = @(
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowTaskViewButton"
        Type        = "DWord"
        Value       = 0
        Description = "Hide Task View button on the taskbar"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "TaskbarAl"
        Type        = "DWord"
        Value       = 0
        Description = "Align taskbar icons to the left"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
        Name        = "TaskbarEndTask"
        Type        = "DWord"
        Value       = 1
        Description = "Enable End Task option in taskbar right-click menu"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowNotificationIcon"
        Type        = "DWord"
        Value       = 0
        Description = "Display the notification bell icon in the system tray"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"
        Name        = "ShowAllPinsList"
        Type        = "DWord"
        Value       = 1
        Description = "Automatically expand to show all pinned apps instead of requiring you to click 'All apps'"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"
        Name        = "ShowRecentList"
        Type        = "DWord"
        Value       = 0
        Description = "Display a list of recently installed applications at the top of the All Apps list"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start"
        Name        = "ShowFrequentList"
        Type        = "DWord"
        Value       = 0
        Description = "Display your frequently launched applications at the top of the All Apps list for quick access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Start_TrackDocs"
        Type        = "DWord"
        Value       = 0
        Description = "Display your recently opened documents and files in the Start Menu's Recommended section for quick access"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Start_IrisRecommendations"
        Type        = "DWord"
        Value       = 0
        Description = "Display personalized suggestions from Windows for tips, app shortcuts, and Microsoft Store apps in the Recommended section"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Start_AccountNotifications"
        Type        = "DWord"
        Value       = 0
        Description = "Display notifications about Microsoft account sign-in, sync status, and account-related suggestions"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        Name        = "SearchboxTaskbarMode"
        Type        = "DWord"
        Value       = 0
        Description = "Choose how the Windows search appears on your taskbar: hidden, icon only, icon with label, or full search box"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        Name        = "SearchboxTaskbarModeCache"
        Type        = "DWord"
        Value       = 0
        Description = "Choose how the Windows search appears on your taskbar: hidden, icon only, icon with label, or full search box"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "TaskbarAl"
        Type        = "DWord"
        Value       = 0
        Description = "Align taskbar icons to the left (classic Windows style) or center (Windows 11 default)"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "ShowTaskViewButton"
        Type        = "DWord"
        Value       = 0
        Description = "Show the Task View button for managing virtual desktops and viewing all open windows at once"
    },
    @{
        Path        = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        Name        = "HideSCAMeetNow"
        Type        = "DWord"
        Value       = 1
        Description = "Disable Meet Now Icon"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
        Name        = "TaskbarEndTask"
        Type        = "DWord"
        Value       = 1
        Description = "Adds an 'End Task' option when right-clicking applications on the taskbar for quick termination"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "Start_TrackProgs"
        Type        = "DWord"
        Value       = 0
        Description = "Windows records which apps you use most frequently to personalize your Start menu and improve search results, making your most-used apps more accessible"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "MultiTaskingAltTabFilter"
        Type        = "DWord"
        Value       = 3
        Description = "Show only traditional open windows in Alt+Tab instead of including Microsoft Edge tabs"
    },
    @{
        Path        = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name        = "TaskbarAnimations"
        Type        = "DWord"
        Value       = 0
        Description = "Controls taskbar animation effects"
    }
)
