$folder = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell"

if (-not (Test-Path $folder)) {
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
}

Copy-Item -Path "$PSScriptRoot\LayoutModification.xml" -Destination $folder -Recurse -Force -ErrorAction SilentlyContinue
