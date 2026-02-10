@{
    Commands = @(
        @{
            Pass    = "Specialize"   # required
            Order   = 10             # required
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MyWorkspace\Scripts\MySetup.ps1"""  # required
        },
        @{
            Pass    = "Specialize"   # required
            Order   = 20             # required
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MySetup\Scripts\Specialize.ps1"""  # required
        },
        @{
            Pass    = "Specialize"   # required
            Order   = 30             # required
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File ""C:\MySetup\Scripts\DefaultUser.ps1"""  # required
        }
    )
}
