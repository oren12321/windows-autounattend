@{
    Commands = @(
        @{
            Pass    = "Specialize"
            Order   = 10
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File "".\Scripts\MySetup.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 20
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File "".\Scripts\Specialize.ps1"""
        },
        @{
            Pass    = "Specialize"
            Order   = 30
            Command = "powershell.exe -WindowStyle ""Normal"" -ExecutionPolicy ""Unrestricted"" -NoProfile -File "".\Scripts\DefaultUser.ps1"""
        },
        @{
            Pass    = "ActiveSetup"
            Order   = 10
            Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File "".\Scripts\RunActiveSetup.ps1"""
        }
    )
}
