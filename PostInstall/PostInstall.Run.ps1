. "{InstallDirectory}\PostInstall\Utils\Logging.ps1"

& "{InstallDirectory}\PostInstall\PostInstall.Main.ps1" -ComponentsDirectory "{ComponentsDirectory}" *>&1 | Add-RotatingLog -Path "{InstallDirectory}\PostInstall\PostInstall.log" -MaxSize 5MB -MaxFiles 5