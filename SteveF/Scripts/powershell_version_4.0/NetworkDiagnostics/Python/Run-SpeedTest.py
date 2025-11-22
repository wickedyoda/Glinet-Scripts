import subprocess
import json
import time
import datetime
from pathlib import Path
from colorama import Fore, Style

# Assuming write_log_entry is already defined

def run_speedtest(log_path: str, speedtest_path: str, timestamp_format: str = "%H:%M:%S"):
    write_log_entry("--- Speed Test ---", log_path, color="Cyan")

    speedtest_exe = Path(speedtest_path) / "speedtest.exe"
    if not speedtest_exe.exists():
        write_log_entry(f"Speedtest CLI not found at {speedtest_exe}", log_path, color="Red")
        return None

    try:
        # Simulate progress bar
        print("Running Speedtest...", end="", flush=True)
        progress = 0
        spinner = ["|", "/", "-", "\\"]
        spin_index = 0

        # Start speedtest process
        process = subprocess.Popen(
            [str(speedtest_exe), "--format=json"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True
        )

        # Show progress while running
        while process.poll() is None:
            print(f"\rTesting... {spinner[spin_index]} {progress}%", end="", flush=True)
            spin_index = (spin_index + 1) % len(spinner)
            progress = (progress + 5) % 100
            time.sleep(0.5)

        print("\rSpeedtest complete.           ")

        stdout, stderr = process.communicate()
        if not stdout:
            write_log_entry("Speedtest failed or returned no data.", log_path, color="Red")
            return None

        result = json.loads(stdout)

        download_mbps = round(result["download"]["bandwidth"] / 125000, 2)
        upload_mbps = round(result["upload"]["bandwidth"] / 125000, 2)
        ping_latency = round(result["ping"]["latency"], 2)
        server_name = f'{result["server"]["name"]} ({result["server"]["location"]})'
        server_id = result["server"]["id"]
        isp_name = result["isp"]

        write_log_entry(f"Download Speed: {download_mbps} Mbps", log_path, color="Green")
        write_log_entry(f"Upload Speed:   {upload_mbps} Mbps", log_path, color="Green")
        write_log_entry(f"Ping Latency:   {ping_latency} ms", log_path, color="Green")
        write_log_entry(f"Server:         {server_name} [ID: {server_id}]", log_path, color="Gray")
        write_log_entry(f"ISP:            {isp_name}", log_path, color="Gray")

        return {
            "Download": download_mbps,
            "Upload": upload_mbps,
            "Ping": ping_latency,
            "Server": server_name,
            "ServerId": server_id,
            "ISP": isp_name
        }

    except Exception as e:
        write_log_entry(f"Speedtest error: {e}", log_path, color="Red")
        return None
