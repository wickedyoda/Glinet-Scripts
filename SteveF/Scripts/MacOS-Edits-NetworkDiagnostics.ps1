# ===============================
# Network Diagnostics Script
# ===============================

function Write-LogEntry {
    param (
        [string]$Message,
        [string]$LogPath,
        [string]$Color = "Gray"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    Write-Host $entry -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $entry
}

function Run-PingTest {
    param (
        [string]$Target,
        [int]$PingCount,
        [int]$RepeatCycles,
        [int]$CycleDelay,
        [string]$LogPath
    )

    # Header for Ping section
    Write-Host "`n--- Ping Test ---" -ForegroundColor Cyan
    Add-Content -Path $LogPath -Value "--- Ping Test ---"

    $allPings = @()
    $successCount = 0
    $totalPings = $PingCount * $RepeatCycles

    for ($i = 1; $i -le $RepeatCycles; $i++) {
        Write-LogEntry -Message "--- Ping Cycle $i of $RepeatCycles ---" -LogPath $LogPath -Color "Cyan"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "ping.exe"
        $psi.Arguments = "$Target -n $PingCount"
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.Start() | Out-Null

        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()

            if ($line -match "time[=<](\d+)ms") {
                $latency = [int]$matches[1]
                $allPings += $latency
                $successCount++
                $color = if ($latency -gt 200) { "Yellow" } else { "Green" }
            } elseif ($line -match "Request timed out") {
                $color = "Red"
            } else {
                $color = "Gray"
            }

            Write-Host $line -ForegroundColor $color
            Add-Content -Path $LogPath -Value $line
        }

        $proc.WaitForExit()
        if ($i -lt $RepeatCycles) { Start-Sleep -Seconds $CycleDelay }
    }

    if ($allPings.Count -gt 0) {
        $avg = [math]::Round(($allPings | Measure-Object -Average).Average,2)
        $min = ($allPings | Measure-Object -Minimum).Minimum
        $max = ($allPings | Measure-Object -Maximum).Maximum
        $successRate = [math]::Round(($successCount / $totalPings) * 100,2)

        # Jitter calculation
        $jitter = 0
        if ($allPings.Count -gt 1) {
            $diffs = @()
            for ($j=1; $j -lt $allPings.Count; $j++) {
                $diffs += [math]::Abs($allPings[$j] - $allPings[$j-1])
            }
            $jitter = [math]::Round(($diffs | Measure-Object -Average).Average,2)
        }
    } else {
        $avg = $min = $max = $successRate = $jitter = 0
    }

    # Labeled summary
    $summaryMsg = "Ping Summary: Success Rate = $successRate% ($successCount/$totalPings), Latency (ms) => Min=$min, Max=$max, Avg=$avg, Jitter=$jitter"
    Write-Host $summaryMsg -ForegroundColor Cyan
    Add-Content -Path $LogPath -Value $summaryMsg

    return @{
        SuccessRate = $successRate
        Min = $min
        Max = $max
        Avg = $avg
        Jitter = $jitter
    }
}

function Run-Traceroute {
    param (
        [string]$Target,
        [string]$LogPath
    )

    # Add blank line before header for visual separation
    Write-Host "`n--- Traceroute ---" -ForegroundColor Cyan
    Add-Content -Path $LogPath -Value "--- Traceroute ---"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "tracert.exe"
    $psi.Arguments = $Target
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    while (-not $proc.StandardOutput.EndOfStream) {
        $line = $proc.StandardOutput.ReadLine()

        if ($line -match "(\d+)\s*ms") {
            $latency = [int]$matches[1]
            $color = if ($latency -gt 200) { "Yellow" } else { "Cyan" }
        } elseif ($line -match "\*") {
            $color = "Red"
        } else {
            $color = "Gray"
        }

        Write-Host $line -ForegroundColor $color
        Add-Content -Path $LogPath -Value $line
    }

    $proc.WaitForExit()
}

function Run-BufferbloatTest {
    param (
        [string]$Target,
        [int]$PacketSize = 1500,
        [string]$LogPath
    )

    $fragmentDetected = $false
    Write-LogEntry -Message "--- Bufferbloat Test ---" -LogPath $LogPath -Color "Cyan"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "ping.exe"
    $psi.Arguments = "$Target -f -l $PacketSize -n 4"
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    while (-not $proc.StandardOutput.EndOfStream) {
        $line = $proc.StandardOutput.ReadLine()
        if ($line -match "Packet needs to be fragmented") {
            $fragmentDetected = $true
            $color = "Yellow"
        } elseif ($line -match "Request timed out") {
            $color = "Red"
        } else {
            $color = "Green"
        }
        Write-Host $line -ForegroundColor $color
        Add-Content -Path $LogPath -Value $line
    }

    $proc.WaitForExit()

    if ($fragmentDetected) {
        $summaryMsg = "Bufferbloat detected! Packet size $PacketSize cannot pass without fragmentation."
        Write-Host $summaryMsg -ForegroundColor Cyan
        Add-Content -Path $LogPath -Value $summaryMsg
        $recommendMsg = "Recommendation: Rerun the test with packet size $(($PacketSize - 20))"
        Write-Host $recommendMsg -ForegroundColor Yellow
        Add-Content -Path $LogPath -Value $recommendMsg
    } else {
        $summaryMsg = "Bufferbloat - no fragmentation detected with packet size $PacketSize."
        Write-Host $summaryMsg -ForegroundColor Cyan
        Add-Content -Path $LogPath -Value $summaryMsg
    }

    return -not $fragmentDetected
}

function Run-Diagnostics {
    param (
        [string]$Target,
        [int]$PingCount,
        [int]$RepeatCycles,
        [int]$CycleDelay,
        [bool]$EnablePing,
        [bool]$EnableTraceroute,
        [bool]$EnableBufferbloat,
        [int]$BufferPacketSize,
        [string]$LogPath
    )

    $pingResult = $null
    $bufferOk = $true

    if ($EnablePing) { $pingResult = Run-PingTest -Target $Target -PingCount $PingCount -RepeatCycles $RepeatCycles -CycleDelay $CycleDelay -LogPath $LogPath }
    if ($EnableTraceroute) { Run-Traceroute -Target $Target -LogPath $LogPath }
    if ($EnableBufferbloat) {
        $bufferSize = $BufferPacketSize
        $bufferOk = $false
        while (-not $bufferOk) {
            $bufferOk = Run-BufferbloatTest -Target $Target -PacketSize $bufferSize -LogPath $LogPath
            if (-not $bufferOk) { $bufferSize -= 20 }
        }
    }

    Write-Host "`n=== Combined Summary ===" -ForegroundColor Cyan
    Add-Content -Path $LogPath -Value "`n=== Combined Summary ==="

    if ($pingResult) {
        $pingSummary = "Ping: Success Rate=$($pingResult.SuccessRate)%, Latency (ms) => Min=$($pingResult.Min), Max=$($pingResult.Max), Avg=$($pingResult.Avg), Jitter=$($pingResult.Jitter)"
        Write-Host $pingSummary -ForegroundColor Cyan
        Add-Content -Path $LogPath -Value $pingSummary
    }

    if ($EnableBufferbloat) {
        $bufferSummary = if ($bufferOk) { "Bufferbloat - no fragmentation detected with packet size $bufferSize" } else { "Bufferbloat: Fragmentation detected." }
        Write-Host $bufferSummary -ForegroundColor Cyan
        Add-Content -Path $LogPath -Value $bufferSummary
    }

    Write-Host "`nFull log saved to $LogPath" -ForegroundColor Cyan
}

# ===============================
# Main Menu
# ===============================
$logDir = "C:\Scripts\Logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$defaultRepeatCycles = 3

do {
    Write-Host "`n=== Network Diagnostic Menu ===" -ForegroundColor Cyan
    Write-Host "1. Full Diagnostic (Ping + Traceroute + Bufferbloat)" -ForegroundColor White
    Write-Host "2. Ping Only" -ForegroundColor White
    Write-Host "3. Traceroute Only" -ForegroundColor White
    Write-Host "4. Bufferbloat Test (4 pings only)" -ForegroundColor White
    Write-Host "5. Exit" -ForegroundColor White

    $choice = Read-Host "Select an option (default 5)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "5" }

    if ($choice -eq "5") { Write-Host "Exiting script..." -ForegroundColor Green; break }

    $logFile = Join-Path $logDir ("NetworkTest_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    $target = Read-Host "Enter domain/IP to test (default 1.1.1.1)"
    if ([string]::IsNullOrWhiteSpace($target)) { $target = "1.1.1.1" }

    $userPingCount = Read-Host "Enter number of pings per cycle (default 4)"
    $pingCount = if ([string]::IsNullOrWhiteSpace($userPingCount)) { 4 } else { [int]$userPingCount }

    $cycleDelayInput = Read-Host "Enter delay in seconds between ping cycles (default 2)"
    $cycleDelay = if ([string]::IsNullOrWhiteSpace($cycleDelayInput)) { 2 } else { [int]$cycleDelay }

    switch ($choice) {
        "1" {
            $packetSizeInput = Read-Host "Enter packet size for Bufferbloat test (default 1500)"
            $bufferSize = if ([string]::IsNullOrWhiteSpace($packetSizeInput)) { 1500 } else { [int]$packetSizeInput }
            Run-Diagnostics -Target $target -PingCount $pingCount -RepeatCycles $defaultRepeatCycles -CycleDelay $cycleDelay -EnablePing $true -EnableTraceroute $true -EnableBufferbloat $true -BufferPacketSize $bufferSize -LogPath $logFile
        }
        "2" { Run-Diagnostics -Target $target -PingCount $pingCount -RepeatCycles $defaultRepeatCycles -CycleDelay $cycleDelay -EnablePing $true -EnableTraceroute $false -EnableBufferbloat $false -BufferPacketSize 0 -LogPath $logFile }
        "3" { Run-Diagnostics -Target $target -PingCount $pingCount -RepeatCycles $defaultRepeatCycles -CycleDelay $cycleDelay -EnablePing $false -EnableTraceroute $true -EnableBufferbloat $false -BufferPacketSize 0 -LogPath $logFile }
        "4" {
            $packetSizeInput = Read-Host "Enter packet size for Bufferbloat test (default 1500)"
            $bufferSize = if ([string]::IsNullOrWhiteSpace($packetSizeInput)) { 1500 } else { [int]$packetSizeInput }
            Run-Diagnostics -Target $target -PingCount $pingCount -RepeatCycles $defaultRepeatCycles -CycleDelay $cycleDelay -EnablePing $false -EnableTraceroute $false -EnableBufferbloat $true -BufferPacketSize $bufferSize -LogPath $logFile
        }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }

} while ($true)
