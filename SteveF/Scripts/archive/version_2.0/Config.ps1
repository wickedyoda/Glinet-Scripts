# Initialize config object if not already defined
if (-not $config) {
    $config = [ordered]@{}
}

# Default settings block
$config.Defaults = [ordered]@{
    # General
    TargetHost       = "8.8.8.8"
    LogDirectory     = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
    TimestampFormat  = "HH:mm:ss"

    # Ping Test
    PingCount        = 4
    PingDelay        = 1000  # milliseconds

    # Bufferbloat / MTU Discovery
    BufferStartSize  = 1500
    MTUStopSize      = 100
    MTUDecrement     = 20

    # Speedtest CLI
    SpeedtestPath    = "$env:USERPROFILE\AppData\Local\Speedtest"

    # Optional toggles
    EnableIPGeo      = $true
}
