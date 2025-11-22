# Load config and modules
. "$PSScriptRoot\Config.ps1"
. "$PSScriptRoot\Get-ValidatedIntInput.ps1"
. "$PSScriptRoot\Run-PingTest.ps1"
. "$PSScriptRoot\Run-TracerouteTest.ps1"
. "$PSScriptRoot\Run-BufferbloatTest.ps1"
. "$PSScriptRoot\Run-SpeedTest.ps1"
. "$PSScriptRoot\Run-IPGeolocationTest.ps1"
. "$PSScriptRoot\Write-LogEntry.ps1"

# Create log directory if needed
if (-not (Test-Path $config.Defaults.LogDirectory)) {
    New-Item -ItemType Directory -Path $config.Defaults.LogDirectory -Force | Out-Null
}

# Main menu loop
do {
    Write-Host "`n--- Network Diagnostics ---" -ForegroundColor Cyan
    Write-Host "1. Ping Test"
    Write-Host "2. Traceroute Test"
    Write-Host "3. Speed Test"
    Write-Host "4. Bufferbloat Test"
    Write-Host "5. IP Geolocation Test"
    Write-Host "6. Run All Tests"
    Write-Host "7. Exit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        '1' {
            $targetInput = Read-Host "Enter target host for Ping Test (default: $($config.Defaults.TargetHost))"
            $target = if ([string]::IsNullOrWhiteSpace($targetInput)) { $config.Defaults.TargetHost } else { $targetInput }

            $count = Get-ValidatedIntInput -Prompt "Ping count" -Default $config.Defaults.PingCount -Min 1 -Max 20 -Label "count"
            $delaySec = Get-ValidatedIntInput -Prompt "Ping delay in seconds" -Default ([math]::Ceiling($config.Defaults.PingDelay / 1000)) -Min 1 -Max 60 -Label "delay"
            $delayMs = $delaySec * 1000

            $logPath = "$($config.Defaults.LogDirectory)\Ping_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Run-PingTest -Target $target -Count $count -Delay $delayMs -LogPath $logPath
        }

        '2' {
            $targetInput = Read-Host "Enter target host for Traceroute (default: $($config.Defaults.TargetHost))"
            $target = if ([string]::IsNullOrWhiteSpace($targetInput)) { $config.Defaults.TargetHost } else { $targetInput }

            $logPath = "$($config.Defaults.LogDirectory)\Traceroute_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Run-TracerouteTest -Target $target -LogPath $logPath
        }

        '3' {
            $logPath = "$($config.Defaults.LogDirectory)\Speedtest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            $speedSummary = Run-SpeedTest -LogPath $logPath

            if ($speedSummary) {
                Write-Host "`n--- Speedtest Results ---" -ForegroundColor Green
                Write-Host "Download: $($speedSummary.Download) Mbps" -ForegroundColor Yellow
                Write-Host "Upload:   $($speedSummary.Upload) Mbps" -ForegroundColor Yellow
                Write-Host "Ping:     $($speedSummary.Ping) ms" -ForegroundColor Yellow
                Write-Host "Server:   $($speedSummary.Server) [ID: $($speedSummary.ServerId)]" -ForegroundColor Gray
                Write-Host "ISP:      $($speedSummary.ISP)" -ForegroundColor Gray
            }
        }

        '4' {
            $targetInput = Read-Host "Enter target for Bufferbloat Test (default: $($config.Defaults.TargetHost))"
            $target = if ([string]::IsNullOrWhiteSpace($targetInput)) { $config.Defaults.TargetHost } else { $targetInput }

            $startSizeInput = Read-Host "Starting packet size for MTU discovery (default: $($config.Defaults.BufferStartSize))"
            $startSize = if ([string]::IsNullOrWhiteSpace($startSizeInput)) {
                $config.Defaults.BufferStartSize
            } elseif ([int]::TryParse($startSizeInput, [ref]$null)) {
                [int]$startSizeInput
            } else {
                $config.Defaults.BufferStartSize
            }

            $logPath = "$($config.Defaults.LogDirectory)\Bufferbloat_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Run-BufferbloatTest -Target $target -StartSize $startSize -LogPath $logPath
        }

        '5' {
            $logPath = "$($config.Defaults.LogDirectory)\IPGeo_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Run-IPGeolocationTest -LogPath $logPath
        }

        '6' {
            $targetInput = Read-Host "Enter target host for full diagnostics (default: $($config.Defaults.TargetHost))"
            $target = if ([string]::IsNullOrWhiteSpace($targetInput)) { $config.Defaults.TargetHost } else { $targetInput }

            $logPath = "$($config.Defaults.LogDirectory)\FullDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

            Write-LogEntry -Message "Running full diagnostics on $target" -LogPath $logPath -Color "Cyan"

            Run-IPGeolocationTest -LogPath $logPath
            $pingSummary = Run-PingTest -Target $target -Count $config.Defaults.PingCount -Delay $config.Defaults.PingDelay -LogPath $logPath
            Run-TracerouteTest -Target $target -LogPath $logPath
            Run-BufferbloatTest -Target $target -StartSize $config.Defaults.BufferStartSize -LogPath $logPath
            $speedSummary = Run-SpeedTest -LogPath $logPath

            # Summary Dashboard
            Write-Host "`n--- Summary Dashboard ---" -ForegroundColor Cyan
            Add-Content -Path $logPath -Value "`n--- Summary Dashboard ---"

            if ($pingSummary) {
                Write-Host "Ping to $($pingSummary.Target): $($pingSummary.AverageLatency)ms avg, $($pingSummary.Jitter)ms jitter, $($pingSummary.LossPercent)% loss" -ForegroundColor Yellow
                Add-Content -Path $logPath -Value "Ping to $($pingSummary.Target): $($pingSummary.AverageLatency)ms avg, $($pingSummary.Jitter)ms jitter, $($pingSummary.LossPercent)% loss"
            }

            if ($speedSummary) {
                Write-Host "`n--- Speedtest Results ---" -ForegroundColor Green
                Write-Host "Download: $($speedSummary.Download) Mbps" -ForegroundColor Yellow
                Write-Host "Upload:   $($speedSummary.Upload) Mbps" -ForegroundColor Yellow
                Write-Host "Ping:     $($speedSummary.Ping) ms" -ForegroundColor Yellow
                Write-Host "Server:   $($speedSummary.Server) [ID: $($speedSummary.ServerId)]" -ForegroundColor Gray
                Write-Host "ISP:      $($speedSummary.ISP)" -ForegroundColor Gray

                Add-Content -Path $logPath -Value "`n--- Speedtest Results ---"
                Add-Content -Path $logPath -Value "Download: $($speedSummary.Download) Mbps"
                Add-Content -Path $logPath -Value "Upload:   $($speedSummary.Upload) Mbps"
                Add-Content -Path $logPath -Value "Ping:     $($speedSummary.Ping) ms"
                Add-Content -Path $logPath -Value "Server:   $($speedSummary.Server) [ID: $($speedSummary.ServerId)]"
                Add-Content -Path $logPath -Value "ISP:      $($speedSummary.ISP)"
            }

            Write-Host "Traceroute and bufferbloat results logged to file." -ForegroundColor Gray
            Add-Content -Path $logPath -Value "Traceroute and bufferbloat results logged to file."
        }

        '7' {
            Write-Host "Exiting diagnostics suite." -ForegroundColor Gray
        }

        default {
            Write-Host "Invalid choice. Please select a valid option." -ForegroundColor Red
        }
    }

} while ($choice -ne '7')
