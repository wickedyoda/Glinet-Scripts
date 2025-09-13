function Run-BufferbloatTest {
    param (
        [string]$Target,
        [int]$StartSize,
        [string]$LogPath
    )

    Write-LogEntry -Message "--- Bufferbloat Test ---" -LogPath $LogPath -Color "Cyan"

    $packetSize = $StartSize
    $minSize = $config.Defaults.MTUStopSize
    $stepSize = $config.Defaults.MTUDecrement

    while ($packetSize -ge $minSize) {
        Write-LogEntry -Message "Testing with packet size: $packetSize bytes" -LogPath $LogPath -Color "Yellow"

        $result = ping -n 4 -f -l $packetSize $Target 2>&1
        $fragmented = $false

        foreach ($line in $result) {
            Add-Content -Path $LogPath -Value $line
            if ($line -match "Packet needs to be fragmented") {
                $fragmented = $true
            }
        }

        if ($fragmented) {
            Write-LogEntry -Message "Bufferbloat detected at $packetSize bytes. Reducing size..." -LogPath $LogPath -Color "Red"
            $packetSize -= $stepSize
        } else {
            Write-LogEntry -Message "Normal ping response at $packetSize bytes. No bufferbloat." -LogPath $LogPath -Color "Green"
            break
        }
    }

    if ($packetSize -lt $minSize) {
        Write-LogEntry -Message "Unable to find non-fragmented size above $minSize bytes." -LogPath $LogPath -Color "DarkRed"
    }

    Write-LogEntry -Message "Bufferbloat test completed." -LogPath $LogPath -Color "Cyan"
}
