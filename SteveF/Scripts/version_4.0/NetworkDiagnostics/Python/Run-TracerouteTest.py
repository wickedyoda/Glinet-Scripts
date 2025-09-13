import subprocess
import datetime
from pathlib import Path
from colorama import Fore, Style

# Assuming write_log_entry is already defined as in the previous script

def run_traceroute_test(target: str, log_path: str, timestamp_format: str = "%H:%M:%S"):
    # Header logs
    write_log_entry("--- Traceroute Test ---", log_path, color="Cyan")
    write_log_entry(f"Target: {target}", log_path, color="Gray")

    # Run tracert command
    try:
        process = subprocess.Popen(
            ["tracert", target],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            shell=True  # Needed on Windows for tracert.exe
        )

        for line in process.stdout:
            timestamp = datetime.datetime.now().strftime(timestamp_format)
            formatted_line = f"[{timestamp}] {line.strip()}"
            print(formatted_line)
            Path(log_path).parent.mkdir(parents=True, exist_ok=True)
            with open(log_path, "a", encoding="utf-8") as log_file:
                log_file.write(formatted_line + "\n")

        process.wait()

    except Exception as e:
        write_log_entry(f"Traceroute failed: {e}", log_path, color="Red")
