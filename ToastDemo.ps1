# PREVENT DUPLICATE WINDOWS
# If the window is already open, don't open another one
if (Get-Process -Name "powershell" | Where-Object { $_.MainWindowTitle -eq "Restart Required" }) { 
    exit 
}

# FORCE STA MODE (Essential for Windows 10)
if ($Host.Runspace.ApartmentState -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Sta -File `"$PSCommandPath`""
    return
}

# LOAD TYPES & ENABLE STYLES
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# THEME DETECTION (Windows 10 Taskbar match)
$bgColor = [System.Drawing.Color]::FromArgb(45, 45, 48) # Dark Taskbar Gray
$titleColor = [System.Drawing.Color]::White
$descColor = [System.Drawing.Color]::FromArgb(180, 180, 180)

# Check for Light Mode
$themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$isLightTheme = Get-ItemPropertyValue -Path $themePath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
if ($isLightTheme -eq 1) {
    $bgColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $titleColor = [System.Drawing.Color]::Black
    $descColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
}

# CREATE FORM
$form = New-Object System.Windows.Forms.Form
$form.Text = "Restart Required"
$form.Size = New-Object System.Drawing.Size(360, 100)
$form.FormBorderStyle = "None"
$form.BackColor = $bgColor
$form.TopMost = $true
$form.Opacity = 0.95
$form.ShowInTaskbar = $false

# Position (Bottom-Right)
$workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($workingArea.Width - 370), ($workingArea.Height - 115))
$form.StartPosition = "Manual"

# UI Elements (Title)
$title = New-Object System.Windows.Forms.Label
$title.Text = "Restart Required"
$title.ForeColor = $titleColor
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10.5)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(15, 15)
$form.Controls.Add($title)

# UI Elements (Description)
$desc = New-Object System.Windows.Forms.Label
$desc.Text = "Please restart your computer to complete Windows installation customizations and maintenance."
$desc.ForeColor = $descColor
$desc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$desc.Size = New-Object System.Drawing.Size(300, 40)
$desc.Location = New-Object System.Drawing.Point(15, 40)
$form.Controls.Add($desc)

# Close Button
$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = "X"
$closeBtn.Size = New-Object System.Drawing.Size(25, 25)
$closeBtn.Location = New-Object System.Drawing.Point(325, 12)
$closeBtn.FlatStyle = "Flat"
$closeBtn.FlatAppearance.BorderSize = 0
$closeBtn.ForeColor = $titleColor
$closeBtn.Add_Click({ $form.Close() })
$form.Controls.Add($closeBtn)

# SHOW DIALOG
$form.ShowDialog() | Out-Null
