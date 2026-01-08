#################################################
########## Base Software Package Setup ##########
#################################################

function Install-Firefox {

    Write-Host "=== Starting Firefox installation ==="

    # Return object template
    $result = [PSCustomObject]@{
        Success = $false
        Error   = ""
    }

    # --------------------------- CONFIG ---------------------------

    $TempDir          = "$env:TEMP\FirefoxInstall"
    $InstallerPath    = "$TempDir\Firefox.msi"
    $LatestVersionUrl = "https://product-details.mozilla.org/1.0/firefox_versions.json"

    # Ensure temp directory exists
    try {
        New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
    } catch {
        $result.Error = "Failed to create temp directory: $_"
        return $result
    }

    # --------------------------- HELPERS ---------------------------

    function Get-LatestFirefoxVersion {
        try {
            $json = Invoke-RestMethod -Uri $LatestVersionUrl -UseBasicParsing
            return $json.LATEST_FIREFOX_VERSION
        }
        catch {
            Write-Host "Failed to fetch latest version info: $_"
            return $null
        }
    }

    function Get-InstalledFirefoxVersion {
        $paths = @(
            "HKLM:\SOFTWARE\Mozilla\Mozilla Firefox",
            "HKLM:\SOFTWARE\WOW6432Node\Mozilla\Mozilla Firefox"
        )

        foreach ($path in $paths) {
            if (Test-Path $path) {
                $current = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                if ($current -and $current.CurrentVersion) {
                    return $current.CurrentVersion
                }
            }
        }
        return $null
    }

    function Uninstall-Firefox {
        Write-Host "Attempting to uninstall existing Firefox..."

        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($key in $uninstallKeys) {
            Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object {
                $props = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
                if ($props.DisplayName -like "*Mozilla Firefox*") {
                    if ($props.UninstallString) {
                        Write-Host "Uninstalling Firefox..."
                        Start-Process "msiexec.exe" -ArgumentList "/x $($_.PSChildName) /qn" -Wait
                        Write-Host "Uninstall completed"
                    }
                }
            }
        }
    }

    function Remove-StartupEntries {
        Write-Host "Removing Firefox from startup entries..."

        $startupPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )

        foreach ($path in $startupPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Name -like "*Firefox*") {
                        Remove-Item $_.PsPath -Force -ErrorAction SilentlyContinue
                        Write-Host "Removed startup entry: $($_.Name)"
                    }
                }
            }
        }
    }

    function Download-Installer($url, $dest) {

        Write-Host "Downloading Firefox MSI from:"
        Write-Host $url

        # Try BITS first
        try {
            Start-BitsTransfer -Source $url -Destination $dest -ErrorAction Stop
            Write-Host "Download completed via BITS"
            return $true
        }
        catch {
            Write-Host "BITS download failed: $_"
        }

        # Fallback to curl.exe
        try {
            Write-Host "Trying curl fallback..."
            curl.exe -L $url -o $dest
            Write-Host "Download completed via curl"
            return $true
        }
        catch {
            Write-Host "curl download failed: $_"
        }

        return $false
    }

    function Is-ValidMSI($path) {
        if (!(Test-Path $path)) { return $false }

        try {
            $bytes = Get-Content -Path $path -Encoding Byte -TotalCount 8
            # MSI signature: D0 CF 11 E0 A1 B1 1A E1
            $msiSig = @(0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1)

            return ($bytes -join ",") -eq ($msiSig -join ",")
        }
        catch {
            return $false
        }
    }
    
    function Normalize-Version($v) {
        if (-not $v) { return $null }

        # Remove leading "v"
        $v = $v.TrimStart("v")

        # Split into components
        $parts = $v.Split(".")
        
        # Take only the first 3 parts (major.minor.build)
        if ($parts.Count -ge 3) {
            return "$($parts[0]).$($parts[1]).$($parts[2])"
        }

        return $v
    }


    # --------------------------- MAIN LOGIC ---------------------------

    $latestVersion = Get-LatestFirefoxVersion
    if (-not $latestVersion) {
        $result.Error = "Could not determine latest Firefox version."
        return $result
    }

    Write-Host "Latest Firefox version: $latestVersion"

    # Build direct MSI URL
    $InstallerUrl = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$latestVersion/win64/en-US/Firefox%20Setup%20$latestVersion.msi"

    # Remove old installer if exists
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

    # Download with validation + retry
    $attempts = 0
    $maxAttempts = 3

    while ($attempts -lt $maxAttempts) {
        $attempts++

        Write-Host "Download attempt $attempts of $maxAttempts..."

        if (Download-Installer -url $InstallerUrl -dest $InstallerPath) {
            if (Is-ValidMSI $InstallerPath) {
                Write-Host "Valid MSI downloaded."
                break
            }
            else {
                Write-Host "Downloaded file is NOT a valid MSI. Retrying..."
                Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Host "Download failed. Retrying..."
        }
    }

    if (!(Is-ValidMSI $InstallerPath)) {
        $result.Error = "Failed to download a valid Firefox MSI after $maxAttempts attempts."
        return $result
    }

    # Uninstall old version if present
    $installedVersion = Get-InstalledFirefoxVersion
    if ($installedVersion) {
        Write-Host "Existing Firefox version detected: $installedVersion"
        Uninstall-Firefox
    }

    # Install MSI
    Write-Host "Installing Firefox..."
    try {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$InstallerPath`" /qn ALLUSERS=1" -Wait
    }
    catch {
        $result.Error = "Installer execution failed: $_"
        return $result
    }

    Start-Sleep -Seconds 3

    # Verify installation by checking firefox.exe
    $exePath = "C:\Program Files\Mozilla Firefox\firefox.exe"
    if (!(Test-Path $exePath)) {
        $result.Error = "Firefox installation failed: firefox.exe not found."
        return $result
    }

    Write-Host "Firefox installed successfully."

    Remove-StartupEntries

    Write-Host "Cleaning up..."
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    $result.Success = $true
    return $result
}

function Install-Brave {

    Write-Host "=== Starting Brave installation (GitHub Silent EXE) ==="

    $result = [PSCustomObject]@{
        Success = $false
        Error   = ""
    }

    $TempDir       = "$env:TEMP\BraveInstall"
    $InstallerPath = "$TempDir\BraveSilent.exe"
    $GitHubApiUrl  = "https://api.github.com/repos/brave/brave-browser/releases/latest"

    try {
        New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
    } catch {
        $result.Error = "Failed to create temp directory: $_"
        return $result
    }

    # ---------------------- Helper Functions ----------------------

    function Normalize-BraveInstalledVersion($v) {
        if (-not $v) { return $null }

        $parts = $v.Split(".")

        # Brave EXE metadata uses: ChromiumMajor.BraveMajor.BraveMinor.BravePatch
        if ($parts.Count -eq 4) {
            return "$($parts[1]).$($parts[2]).$($parts[3])"
        }

        # Already normalized
        if ($parts.Count -eq 3) {
            return $v
        }

        return $v
    }

    function Normalize-BraveGitHubVersion($v) {
        if (-not $v) { return $null }
        return $v.TrimStart("v")
    }

    function Get-InstalledBraveVersion {
        $paths = @(
            "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
            "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe",
            "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
        )

        foreach ($path in $paths) {
            if (Test-Path $path) {
                try {
                    $info = (Get-Item $path).VersionInfo
                    return $info.ProductVersion
                }
                catch {}
            }
        }

        return $null
    }

    function Uninstall-Brave {
        Write-Host "Attempting to uninstall existing Brave..."

        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($key in $uninstallKeys) {
            Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object {
                $props = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
                if ($props.DisplayName -like "*Brave*") {
                    if ($props.UninstallString) {
                        Write-Host "Uninstalling Brave..."
                        Start-Process $props.UninstallString -ArgumentList "--silent" -Wait
                        Write-Host "Uninstall completed"
                    }
                }
            }
        }
    }

    function Remove-StartupEntries {
        Write-Host "Removing Brave from startup entries..."

        $startupPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )

        foreach ($path in $startupPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Name -like "*Brave*") {
                        Remove-Item $_.PsPath -Force -ErrorAction SilentlyContinue
                        Write-Host "Removed startup entry: $($_.Name)"
                    }
                }
            }
        }
    }

    function Download-Installer($url, $dest) {

        Write-Host "Downloading Brave silent installer from:"
        Write-Host $url

        try {
            Start-BitsTransfer -Source $url -Destination $dest -ErrorAction Stop
            Write-Host "Download completed via BITS"
            return $true
        }
        catch {
            Write-Host "BITS download failed: $_"
        }

        try {
            Write-Host "Trying curl fallback..."
            curl.exe -L $url -o $dest
            Write-Host "Download completed via curl"
            return $true
        }
        catch {
            Write-Host "curl download failed: $_"
        }

        return $false
    }

    function Get-BraveSilentInstallerUrl {
        Write-Host "Querying GitHub API for latest Brave release..."

        try {
            $response = Invoke-RestMethod -Uri $GitHubApiUrl -Headers @{ "User-Agent" = "PowerShell" }
        }
        catch {
            Write-Host "Failed to query GitHub API: $_"
            return $null
        }

        foreach ($asset in $response.assets) {
            if ($asset.name -eq "BraveBrowserStandaloneSilentSetup.exe") {
                return $asset.browser_download_url, $response.tag_name.TrimStart("v")
            }
        }

        return $null
    }

    # ---------------------- Version Check ----------------------

    $installedVersion = Get-InstalledBraveVersion
    $installedNorm = Normalize-BraveInstalledVersion $installedVersion

    Write-Host "Installed Brave version: $installedVersion (normalized: $installedNorm)"

    $installerInfo = Get-BraveSilentInstallerUrl
    if (-not $installerInfo) {
        $result.Error = "Could not find Brave silent installer in GitHub release."
        return $result
    }

    $InstallerUrl = $installerInfo[0]
    $latestVersion = $installerInfo[1]
    $latestNorm = Normalize-BraveGitHubVersion $latestVersion

    Write-Host "Latest Brave version: $latestVersion (normalized: $latestNorm)"

    if ($installedNorm -and ($installedNorm -eq $latestNorm)) {
        Write-Host "Brave is already up to date. No installation needed."
        $result.Success = $true
        return $result
    }

    Write-Host "Brave is outdated or missing. Proceeding with installation..."

    # ---------------------- Download & Install ----------------------

    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

    if (-not (Download-Installer -url $InstallerUrl -dest $InstallerPath)) {
        $result.Error = "Failed to download Brave silent installer."
        return $result
    }

    # Kill running Brave processes
    Get-Process brave -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    if ($installedVersion) {
        Uninstall-Brave
    }

    Write-Host "Installing Brave..."
    try {
        Start-Process $InstallerPath -Wait
    }
    catch {
        $result.Error = "Installer execution failed: $_"
        return $result
    }

    Start-Sleep -Seconds 3

    # Check all possible install paths
    $possiblePaths = @(
        "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
        "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
    )

    $exePath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $exePath) {
        $result.Error = "Brave installation failed: brave.exe not found in any known location."
        return $result
    }

    Write-Host "Brave installed successfully at: $exePath"

    Remove-StartupEntries

    Write-Host "Cleaning up..."
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    $result.Success = $true
    return $result
}

function Install-FreeProtonVPN {

    Write-Host "=== Installing/Updating ProtonVPN Free (Winget) ==="

    $result = [PSCustomObject]@{
        Success = $false
        Error   = ""
    }

    try {
        Write-Host "Refreshing Winget sources..."
        winget source reset --force 2>$null
        winget source update 2>$null
    }
    catch {
        $result.Error = "Failed to refresh Winget sources: $_"
        return $result
    }

    # Check if ProtonVPN is installed
    try {
        $installed = winget list --id Proton.ProtonVPN --source winget 2>$null
    }
    catch {
        $result.Error = "Winget list failed: $_"
        return $result
    }

    try {
        if ($installed -match "ProtonVPN") {
            Write-Host "ProtonVPN is already installed. Updating..."
            winget upgrade Proton.ProtonVPN `
                --silent `
                --accept-source-agreements `
                --accept-package-agreements `
                --force `
                --disable-interactivity `
                2>$null
        }
        else {
            Write-Host "ProtonVPN not installed. Installing..."
            winget install Proton.ProtonVPN `
                --silent `
                --accept-source-agreements `
                --accept-package-agreements `
                --force `
                --disable-interactivity `
                2>$null
        }
    }
    catch {
        $result.Error = "Winget installation/upgrade failed: $_"
        return $result
    }

    # Verify installation
    try {
        $installedCheck = winget list --id Proton.ProtonVPN --source winget 2>$null
        if (-not ($installedCheck -like "*ProtonVPN*")) {
            $result.Error = "ProtonVPN installation or update did not complete successfully."
            return $result
        }
    }
    catch {
        $result.Error = "Failed to verify ProtonVPN installation: $_"
        return $result
    }

    Write-Host "ProtonVPN installed/updated successfully."
    $result.Success = $true
    return $result
}

function Install-qBittorrent {

    Write-Host "=== Installing/Updating qBittorrent (Winget) ==="

    $result = [PSCustomObject]@{
        Success = $false
        Error   = ""
    }

    try {
        Write-Host "Refreshing Winget sources..."
        winget source reset --force 2>$null
        winget source update 2>$null
    }
    catch {
        $result.Error = "Failed to refresh Winget sources: $_"
        return $result
    }

    # Check if qBittorrent is installed
    try {
        $installed = winget list --id qBittorrent.qBittorrent --source winget 2>$null
    }
    catch {
        $result.Error = "Winget list failed: $_"
        return $result
    }

    try {
        if ($installed -like "*qBittorrent*") {
            Write-Host "qBittorrent is already installed. Updating..."
            winget upgrade qBittorrent.qBittorrent `
                --silent `
                --accept-source-agreements `
                --accept-package-agreements `
                --force `
                --disable-interactivity `
                2>$null
        }
        else {
            Write-Host "qBittorrent not installed. Installing..."
            winget install qBittorrent.qBittorrent `
                --silent `
                --accept-source-agreements `
                --accept-package-agreements `
                --force `
                --disable-interactivity `
                2>$null
        }
    }
    catch {
        $result.Error = "Winget installation/upgrade failed: $_"
        return $result
    }

    # Verify installation
    try {
        $installedCheck = winget list --id qBittorrent.qBittorrent --source winget 2>$null
        if (-not ($installedCheck -like "*qBittorrent*")) {
            $result.Error = "qBittorrent installation or update did not complete successfully."
            return $result
        }
    }
    catch {
        $result.Error = "Failed to verify qBittorrent installation: $_"
        return $result
    }

    Write-Host "qBittorrent installed/updated successfully."
    $result.Success = $true
    return $result
}