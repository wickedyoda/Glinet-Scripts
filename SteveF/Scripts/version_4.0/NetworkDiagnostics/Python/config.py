import os

# Default configuration settings
config = {
    "Defaults": {
        "LogDirectory": os.path.join(os.path.dirname(__file__), "logs"),
        "TargetHost": "8.8.8.8",
        "PingCount": 4,
        "PingDelay": 1000,  # milliseconds
        "BufferStartSize": 1200,
    }
}
