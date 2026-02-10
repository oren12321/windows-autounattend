# ============================================================
# MySetup.ps1
# Runs during SPECIALIZE pass
# Creates persistent setup folder structure and
# copies original Setup scripts for post-upgrade reuse.
# ============================================================

$SetupDir = "C:\MySetup"
$ScriptsDir = Join-Path $SetupDir "Scripts"
$LogDir          = Join-Path $SetupDir "Logs"
$StateDir        = Join-Path $SetupDir "State"

# --- Create folder structure ---
$folders = @(
    $ScriptsDir,
    $LogDir,
    $StateDir
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# --- Copy original Setup scripts ---
$Source = "$PSScriptRoot"

if (Test-Path $Source) {
    Copy-Item -Path "$Source\*" -Destination $ScriptsDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
    # Optional: log a warning if needed
}

# --- Store current OS build number ---
$Build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$Build | Out-File -FilePath (Join-Path $StateDir "LastBuild.txt") -Encoding ASCII -Force