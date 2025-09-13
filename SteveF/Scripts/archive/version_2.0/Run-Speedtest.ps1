function Run-SpeedTest {
    param (
        [string]$LogPath
    )

    Write-LogEntry -Message "--- Speed Test ---" -LogPath $LogPath -Color "Cyan"

    $speedtestExe = Join-Path $config.Defaults.SpeedtestPath "speedtest.exe"

    if (-not (Test-Path $speedtestExe)) {
        Write-LogEntry -Message "Speedtest CLI not found at $speedtestExe" -LogPath $LogPath -Color "Red"
        return
    }

    # Start speedtest in background
    $job = Start-Job -ScriptBlock {
        & $using:speedtestExe --format=json
    }

    $progress = 0
    while ($job.State -eq 'Running') {
        Write-Progress -Activity "Running Speedtest" -Status "Testing..." -PercentComplete $progress
        Start-Sleep -Milliseconds 500
        $progress = ($progress + 5) % 100
    }

    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    Write-Progress -Activity "Running Speedtest" -Completed

    if (-not $result) {
        Write-LogEntry -Message "Speedtest failed or returned no data." -LogPath $LogPath -Color "Red"
        return
    }

    $json = $result | ConvertFrom-Json

    Write-LogEntry -Message "Download Speed: $($json.download.bandwidth / 125000) Mbps" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Upload Speed:   $($json.upload.bandwidth / 125000) Mbps" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Ping Latency:   $($json.ping.latency) ms" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Server:         $($json.server.name) ($($json.server.location)) [ID: $($json.server.id)]" -LogPath $LogPath -Color "Gray"
    Write-LogEntry -Message "ISP:            $($json.isp)" -LogPath $LogPath -Color "Gray"
}
