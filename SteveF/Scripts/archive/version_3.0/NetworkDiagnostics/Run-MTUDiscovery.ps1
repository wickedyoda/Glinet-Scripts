function Run-MTUDiscovery {
    param (
        [string]$Target,
        [int]$StartSize = 1500,
        [int]$MinSize = 100,
        [int]$StepSize = 20,
        [string]$LogPath
    )

    Write-LogEntry -Message "--- MTU Discovery ---" -LogPath $LogPath -Color "Cyan"

    for ($size = $StartSize; $size -ge $MinSize; $size -= $StepSize) {
        $result = ping -n 1 -f -l $size $Target 2>&1

        if ($result -notmatch "Packet needs to be fragmented") {
            Write-LogEntry -Message "MTU discovered: $size bytes" -LogPath $LogPath -Color "Green"
            return $size
        } else {
            Write-LogEntry -Message "Fragmentation at $size bytes" -LogPath $LogPath -Color "DarkYellow"
        }
    }

    Write-LogEntry -Message "MTU discovery failed. No non-fragmented size found." -LogPath $LogPath -Color "Red"
    return $null
}
