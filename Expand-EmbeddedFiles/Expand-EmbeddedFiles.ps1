function Expand-EmbeddedFiles {
    param(
        [xml] $Document
    )

    foreach ($file in $Document.unattend.Extensions.File) {
        $path = [System.Environment]::ExpandEnvironmentVariables($file.GetAttribute('path'))
        $ext  = [System.IO.Path]::GetExtension($path).ToLower()

        # Ensure parent directory exists
        $parent = Split-Path $path -Parent
        if ($parent) {
            mkdir -Path $parent -ErrorAction SilentlyContinue | Out-Null
        }

        if ($ext -in '.zip', '.exe', '.dll', '.msi') {
            # Binary-safe extraction
            $bytes = [Convert]::FromBase64String($file.InnerText.Trim())
            [System.IO.File]::WriteAllBytes($path, $bytes)
            continue
        }

        # Text-based extraction
        $encoding = switch ($ext) {
            '.ps1' { [System.Text.Encoding]::UTF8 }
            '.xml' { [System.Text.Encoding]::UTF8 }
            '.reg' { [System.Text.UnicodeEncoding]::new($false, $true) }
            '.vbs' { [System.Text.UnicodeEncoding]::new($false, $true) }
            '.js'  { [System.Text.UnicodeEncoding]::new($false, $true) }
            default { [System.Text.Encoding]::Default }
        }

        $bytes = $encoding.GetPreamble() + $encoding.GetBytes($file.InnerText.Trim())
        [System.IO.File]::WriteAllBytes($path, $bytes)
    }
}
