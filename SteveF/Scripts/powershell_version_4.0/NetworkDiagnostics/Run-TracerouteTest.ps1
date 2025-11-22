param (
    [string]$Target = "8.8.8.8",
    [string]$LogPath = "$PSScriptRoot\logs\Traceroute.log"
)

# Ensure logs directory exists
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Run-TracerouteTest {
    param (
        [string]$Target,
        [string]$LogPath
    )

    # Graceful fallback for Write-LogEntry
    if (-not (Get-Command Write-LogEntry -ErrorAction SilentlyContinue)) {
        function Write-LogEntry {
            param (
                [string]$Message,
                [string]$LogPath,
                [string]$Color = "White"
            )
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] $Message" -ForegroundColor $Color
            if ($LogPath) {
                Add-Content -Path $LogPath -Value "[$timestamp] $Message"
            }
        }
    }

    # Graceful fallback for timestamp format if $config isn't loaded
    if (-not $config) {
        $timestampFormat = "yyyy-MM-dd HH:mm:ss"
    } else {
        $timestampFormat = $config.Defaults.TimestampFormat
    }

    Write-LogEntry -Message "--- Traceroute Test ---" -LogPath $LogPath -Color "Cyan"
    Write-LogEntry -Message "Target: $Target" -LogPath $LogPath -Color "Gray"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "tracert.exe"
    $psi.Arguments = $Target
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null

    while (-not $process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
        $timestamp = Get-Date -Format $timestampFormat
        Write-Host "[$timestamp] $line"
        if ($LogPath) {
            Add-Content -Path $LogPath -Value "[$timestamp] $line"
        }
    }

    $process.WaitForExit()
}

# --- Detect if script is run directly (not dot-sourced) ---
if ($MyInvocation.InvocationName -ne ".") {
    Run-TracerouteTest -Target $Target -LogPath $LogPath

    Write-Host "`nTraceroute test complete. Press any key to exit..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)
}
