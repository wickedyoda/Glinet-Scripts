function Run-SpeedTest {
    param (
        [string]$LogPath
    )

    Write-LogEntry -Message "--- Speed Test ---" -LogPath $LogPath -Color "Cyan"

    $speedtestExe = Join-Path $config.Defaults.SpeedtestPath "speedtest.exe"

    if (-not (Test-Path $speedtestExe)) {
        Write-LogEntry -Message "Speedtest CLI not found at $speedtestExe" -LogPath $LogPath -Color "Red"
        return $null
    }

    # Run Speedtest in background with progress meter
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
        return $null
    }

    $json = $result | ConvertFrom-Json

    $downloadMbps = [math]::Round($json.download.bandwidth / 125000, 2)
    $uploadMbps   = [math]::Round($json.upload.bandwidth / 125000, 2)
    $pingLatency  = [math]::Round($json.ping.latency, 2)
    $serverName   = "$($json.server.name) ($($json.server.location))"
    $serverId     = $json.server.id
    $ispName      = $json.isp

    Write-LogEntry -Message "Download Speed: $downloadMbps Mbps" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Upload Speed:   $uploadMbps Mbps" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Ping Latency:   $pingLatency ms" -LogPath $LogPath -Color "Green"
    Write-LogEntry -Message "Server:         $serverName [ID: $serverId]" -LogPath $LogPath -Color "Gray"
    Write-LogEntry -Message "ISP:            $ispName" -LogPath $LogPath -Color "Gray"

    return [PSCustomObject]@{
        Download = $downloadMbps
        Upload   = $uploadMbps
        Ping     = $pingLatency
        Server   = $serverName
        ServerId = $serverId
        ISP      = $ispName
    }
}
