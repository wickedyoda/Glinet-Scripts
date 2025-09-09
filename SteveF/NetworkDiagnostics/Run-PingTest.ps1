function Run-PingTest {
    param (
        [string]$Target,
        [int]$Count = 4,
        [int]$Delay = 1000,
        [string]$LogPath
    )

    Write-LogEntry -Message "--- Ping Test ---" -LogPath $LogPath -Color "Cyan"
    Write-LogEntry -Message "Pinging ${Target} with 32 bytes of data:" -LogPath $LogPath -Color "Gray"
    Write-Host "`nPinging ${Target} with 32 bytes of data:`n" -ForegroundColor Cyan

    $latencies = @()
    $successCount = 0

    for ($i = 1; $i -le $Count; $i++) {
        $result = Test-Connection -ComputerName $Target -Count 1 -ErrorAction SilentlyContinue
        if ($result) {
            $latency = $result.ResponseTime
            $latencies += $latency
            $successCount++
            Write-Host "Reply from ${Target}: bytes=32 time=${latency}ms TTL=$($result.TimeToLive)" -ForegroundColor Green
            Add-Content -Path $LogPath -Value "Reply from ${Target}: bytes=32 time=${latency}ms TTL=$($result.TimeToLive)"
        } else {
            Write-Host "Request timed out." -ForegroundColor Red
            Add-Content -Path $LogPath -Value "Request timed out."
        }
        Start-Sleep -Milliseconds $Delay
    }

    # Summary
    $loss = $Count - $successCount
    $lossPercent = [math]::Round(($loss / $Count) * 100, 2)

    $avg = if ($latencies.Count -gt 0) {
        [math]::Round(($latencies | Measure-Object -Average).Average, 2)
    } else { "N/A" }

    $jitter = if ($latencies.Count -gt 1) {
        $diffs = for ($i = 1; $i -lt $latencies.Count; $i++) {
            [math]::Abs($latencies[$i] - $latencies[$i - 1])
        }
        [math]::Round(($diffs | Measure-Object -Average).Average, 2)
    } else { "N/A" }

    $min = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Minimum).Minimum, 2) } else { "N/A" }
    $max = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Maximum).Maximum, 2) } else { "N/A" }

    Write-Host "`nPing statistics for ${Target}:" -ForegroundColor Cyan
    Write-Host "    Packets: Sent = ${Count}, Received = ${successCount}, Lost = ${loss} (${lossPercent}% loss)" -ForegroundColor Gray
    Write-Host "Approximate round trip times in milliseconds:" -ForegroundColor Gray
    Write-Host "    Minimum = ${min}ms, Maximum = ${max}ms, Average = ${avg}ms, Jitter = ${jitter}ms" -ForegroundColor Yellow

    Add-Content -Path $LogPath -Value "`nPing statistics for ${Target}:"
    Add-Content -Path $LogPath -Value "    Packets: Sent = ${Count}, Received = ${successCount}, Lost = ${loss} (${lossPercent}% loss)"
    Add-Content -Path $LogPath -Value "    Minimum = ${min}ms, Maximum = ${max}ms, Average = ${avg}ms, Jitter = ${jitter}ms"

    return [PSCustomObject]@{
        Target         = $Target
        Sent           = $Count
        Received       = $successCount
        Lost           = $loss
        LossPercent    = $lossPercent
        AverageLatency = $avg
        Jitter         = $jitter
        MinLatency     = $min
        MaxLatency     = $max
    }
}
