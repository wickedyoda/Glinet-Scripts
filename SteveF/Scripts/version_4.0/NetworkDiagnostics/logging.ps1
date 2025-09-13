# --- Logging Function ---
function Write-LogEntry {
    param (
        [string]$Message,
        [string]$LogPath,
        [string]$Color = "White"
    )
    if (-not $LogPath) {
        Write-Host "⚠️ LogPath is undefined or empty. Skipping log write." -ForegroundColor Red
        return
    }
    $timestampedMessage = "$(Get-Date -Format 'HH:mm:ss') $Message"
    Write-Host $timestampedMessage -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $timestampedMessage
}
