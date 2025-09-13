#!/bin/bash

# Path to Windows-based speedtest.exe (used in WSL fallback)
SPEEDTEST_PATH="/mnt/c/Tools/SpeedtestCLI"

# Path to Windows tracert.exe (used if Linux traceroute is unavailable)
TRACERT_PATH="/mnt/c/Windows/System32"

# Minimum MTU to test during discovery
MIN_MTU=1200

# Maximum MTU to start probing from
MAX_MTU=1500

# Step size for MTU decrement (can be adjusted for finer granularity)
MTU_STEP=10

# Default target for diagnostics if none is provided
DEFAULT_TARGET="8.8.8.8"

# Toggle to suppress warnings about missing tools (true/false)
SUPPRESS_WARNINGS=false

# Optional: enable debug mode for verbose output
DEBUG_MODE=false
