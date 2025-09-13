function Run-TracerouteTest {
    param (
        [string]$Target,
        [string]$LogPath
    )

    Write-LogEntry -Message "--- Traceroute Test ---" -LogPath $LogPath -Color "Cyan"
    Write-LogEntry -Message "Target: $Target" -LogPath $LogPath -Color "Gray"

    $tracerouteCmd = if ($IsWindows) { "tracert.exe" } else { "traceroute" }

    if (-not (Get-Command $tracerouteCmd -ErrorAction SilentlyContinue)) {
        Write-LogEntry -Message "Traceroute command '$tracerouteCmd' not found." -LogPath $LogPath -Color "Red"
        return
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $tracerouteCmd
    $psi.Arguments = $Target
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $process = [System.Diagnostics.Process]::Start($psi)
    } catch {
        Write-LogEntry -Message "Failed to start traceroute: $_" -LogPath $LogPath -Color "Red"
        return
    }

    if ($null -eq $process -or $null -eq $process.StandardOutput) {
        Write-LogEntry -Message "Traceroute did not produce any output." -LogPath $LogPath -Color "Red"
        return
    }

    while (-not $process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
        $timestamp = Get-Date -Format $config.Defaults.TimestampFormat
        Write-Host "[$timestamp] $line"
        Add-Content -Path $LogPath -Value "[$timestamp] $line"
    }

    $process.WaitForExit()
}
