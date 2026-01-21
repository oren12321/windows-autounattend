param(
    [string]$ToastTitle = "User Restart Required",
    [string]$ToastText  = "Please log in/out or restart to complete user customizations."
)

# Real UI omitted here – use your existing implementation
Write-Host "TOAST: $ToastTitle - $ToastText"
