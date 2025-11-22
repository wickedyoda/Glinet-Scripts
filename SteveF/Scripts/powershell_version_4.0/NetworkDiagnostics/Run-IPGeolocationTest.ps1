function Run-IPGeolocationTest {
    param ([string]$LogPath)

    Write-LogEntry -Message "--- IP Geolocation Test ---" -LogPath $LogPath -Color "Cyan"

    $fallbackIPs = @(
        "https://api.ipify.org?format=json",
        "https://ipinfo.io/json",
        "https://ifconfig.me/ip"
    )

    $externalIP = $null

    foreach ($url in $fallbackIPs) {
        try {
            $response = Invoke-RestMethod -Uri $url
            $externalIP = if ($response.ip) { $response.ip } else { $response }
            if ($externalIP) {
                Write-LogEntry -Message "Detected external IP: $externalIP" -LogPath $LogPath -Color "Green"
                break
            }
        } catch {
            $msg = "Failed to retrieve IP from $url - " + $_.Exception.Message
            Write-LogEntry -Message $msg -LogPath $LogPath -Color "Yellow"
        }
    }

    if (-not $externalIP) {
        Write-LogEntry -Message "Unable to determine external IP address." -LogPath $LogPath -Color "Red"
        return
    }

    try {
        $geoResult = Invoke-RestMethod -Uri "http://ip-api.com/json/$externalIP"
        if ($geoResult.status -eq "success") {
            $locationInfo = @(
                "ISP: $($geoResult.isp)",
                "City: $($geoResult.city)",
                "Region: $($geoResult.regionName)",
                "Country: $($geoResult.country)",
                "Timezone: $($geoResult.timezone)"
            ) -join ", "
            Write-LogEntry -Message $locationInfo -LogPath $LogPath -Color "Gray"
            Write-LogEntry -Message ("Raw JSON: " + ($geoResult | ConvertTo-Json -Depth 3)) -LogPath $LogPath -Color "DarkGray"
        } else {
            Write-LogEntry -Message "Geolocation lookup failed for $externalIP" -LogPath $LogPath -Color "Red"
        }
    } catch {
        $line = $MyInvocation.ScriptLineNumber
        $errorMsg = "Error in line ${line}: " + $_.Exception.Message
        Write-LogEntry -Message $errorMsg -LogPath $LogPath -Color "Red"
    }
}
