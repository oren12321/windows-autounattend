$donePath = "C:\MySetup\State\FirstUserDone.txt";
if (-not (Test-Path $donePath)) {
    New-Item -Path "$donePath" -ItemType "File" -Force | Out-Null
    & "C:\MySetup\Scripts\UserSetup.ps1" "FirstUser"
}
& "C:\MySetup\Scripts\UserSetup.ps1" "PerUser"