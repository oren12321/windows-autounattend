@{
    Commands = @(
        @{
            Pass    = "Specialize"   # required
            Order   = 10             # required
            Command = "powershell.exe -File .\Setup.ps1"  # required
        },
        @{
            Pass    = "FirstLogon"
            Order   = 5
            Command = "powershell.exe -File .\PostInstall.ps1"
        },
        @{
            Pass    = "ActiveSetup"
            Order   = 1
            Command = "powershell.exe -File .\UserInit.ps1"
        }
    )
}
