function Write-LogEntry {
    param (
        [string]$Message,
        [string]$LogPath,
        [string]$Color = "Gray"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $entry = "$timestamp $Message"

    Write-Host $entry -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $entry
}
