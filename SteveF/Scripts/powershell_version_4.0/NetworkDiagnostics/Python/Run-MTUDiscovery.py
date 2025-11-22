import subprocess
from pathlib import Path
from colorama import Fore, Style

# Assuming write_log_entry is already defined

def run_mtu_discovery(target: str, start_size: int = 1500, min_size: int = 100, step_size: int = 20, log_path: str = "mtu_log.txt"):
    write_log_entry("--- MTU Discovery ---", log_path, color="Cyan")

    for size in range(start_size, min_size - 1, -step_size):
        try:
            result = subprocess.run(
                ["ping", target, "-n", "1", "-f", "-l", str(size)],
                capture_output=True,
                text=True,
                shell=True
            )
            output = result.stdout + result.stderr

            if "Packet needs to be fragmented" not in output:
                write_log_entry(f"MTU discovered: {size} bytes", log_path, color="Green")
                return size
            else:
                write_log_entry(f"Fragmentation at {size} bytes", log_path, color="Yellow")

        except Exception as e:
            write_log_entry(f"Error at size {size}: {e}", log_path, color="Red")

    write_log_entry("MTU discovery failed. No non-fragmented size found.", log_path, color="Red")
    return None
