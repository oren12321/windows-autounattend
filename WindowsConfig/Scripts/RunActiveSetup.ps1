$donePath = "$PSScriptRoot\..\State\FirstUserDone.txt";
if (-not (Test-Path $donePath)) {
    New-Item -Path "$donePath" -ItemType "File" -Force | Out-Null
    & "$PSScriptRoot\UserSetup.ps1" "FirstUser"
}
& "$PSScriptRoot\UserSetup.ps1" "PerUser"
