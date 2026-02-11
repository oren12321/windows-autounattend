@{
    Commands = @(
        @{
            Pass    = "Specialize"
            Order   = 10
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""`$PSScriptRoot\Scripts\MySetup.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 20
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""`$PSScriptRoot\Scripts\Specialize.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 30
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""`$PSScriptRoot\Scripts\DefaultUser.ps1"""
        },
        @{
            Pass    = "ActiveSetup"
            Order   = 10
            Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""`$PSScriptRoot\Scripts\RunActiveSetup.ps1"""
        }
    )
}
