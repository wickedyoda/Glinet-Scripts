function Run-TracerouteTest {
    param (
        [string]$Target,
        [string]$LogPath
    )

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
        $timestamp = Get-Date -Format $config.Defaults.TimestampFormat
        Write-Host "[$timestamp] $line"
        Add-Content -Path $LogPath -Value "[$timestamp] $line"
    }

    $process.WaitForExit()
}
