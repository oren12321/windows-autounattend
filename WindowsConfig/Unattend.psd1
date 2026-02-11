@{
    Commands = @(
        @{
            Pass    = "Specialize"
            Order   = 10
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MyWorkspace\Scripts\MySetup.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 20
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MySetup\Scripts\Specialize.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 30
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MySetup\Scripts\DefaultUser.ps1"""
        },
        @{
            Pass    = "ActiveSetup"
            Order   = 10
            Command = "cmd.exe /c start ""Customizing User ... - Do Not Close The Window"" powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\MySetup\Scripts\RunActiveSetup.ps1"""
        }
    )
}
