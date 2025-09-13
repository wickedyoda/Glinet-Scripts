import subprocess
import time
import statistics
from pathlib import Path
from colorama import Fore, Style

# Assuming write_log_entry is already defined

def run_ping_test(target: str, count: int = 4, delay_ms: int = 1000, log_path: str = "ping_log.txt"):
    write_log_entry("--- Ping Test ---", log_path, color="Cyan")
    write_log_entry(f"Pinging {target} with 32 bytes of data:", log_path, color="Gray")
    print(f"\n{Fore.CYAN}Pinging {target} with 32 bytes of data:\n{Style.RESET_ALL}")

    latencies = []
    success_count = 0

    for i in range(count):
        try:
            result = subprocess.run(
                ["ping", target, "-n", "1", "-w", str(delay_ms)],
                capture_output=True,
                text=True,
                shell=True
            )
            output = result.stdout
            if "Reply from" in output:
                # Extract latency
                try:
                    latency_str = next(
                        (part for part in output.split() if "time=" in part),
                        "time=0ms"
                    ).replace("time=", "").replace("ms", "")
                    latency = float(latency_str)
                    latencies.append(latency)
                    success_count += 1
                    print(f"{Fore.GREEN}Reply from {target}: bytes=32 time={latency}ms TTL=?{Style.RESET_ALL}")
                    with open(log_path, "a", encoding="utf-8") as log_file:
                        log_file.write(f"Reply from {target}: bytes=32 time={latency}ms TTL=?\n")
                except Exception:
                    pass
            else:
                print(f"{Fore.RED}Request timed out.{Style.RESET_ALL}")
                with open(log_path, "a", encoding="utf-8") as log_file:
                    log_file.write("Request timed out.\n")
        except Exception as e:
            print(f"{Fore.RED}Ping failed: {e}{Style.RESET_ALL}")
            with open(log_path, "a", encoding="utf-8") as log_file:
                log_file.write(f"Ping failed: {e}\n")
        time.sleep(delay_ms / 1000)

    # Summary
    loss = count - success_count
    loss_percent = round((loss / count) * 100, 2) if count else 0

    avg = round(statistics.mean(latencies), 2) if latencies else "N/A"
    jitter = round(statistics.mean([abs(latencies[i] - latencies[i - 1]) for i in range(1, len(latencies))]), 2) if len(latencies) > 1 else "N/A"
    min_latency = round(min(latencies), 2) if latencies else "N/A"
    max_latency = round(max(latencies), 2) if latencies else "N/A"

    print(f"\n{Fore.CYAN}Ping statistics for {target}:{Style.RESET_ALL}")
    print(f"{Fore.LIGHTBLACK_EX}    Packets: Sent = {count}, Received = {success_count}, Lost = {loss} ({loss_percent}% loss){Style.RESET_ALL}")
    print(f"{Fore.LIGHTBLACK_EX}Approximate round trip times in milliseconds:{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}    Minimum = {min_latency}ms, Maximum = {max_latency}ms, Average = {avg}ms, Jitter = {jitter}ms{Style.RESET_ALL}")

    with open(log_path, "a", encoding="utf-8") as log_file:
        log_file.write(f"\nPing statistics for {target}:\n")
        log_file.write(f"    Packets: Sent = {count}, Received = {success_count}, Lost = {loss} ({loss_percent}% loss)\n")
        log_file.write(f"    Minimum = {min_latency}ms, Maximum = {max_latency}ms, Average = {avg}ms, Jitter = {jitter}ms\n")

    return {
        "Target": target,
        "Sent": count,
        "Received": success_count,
        "Lost": loss,
        "LossPercent": loss_percent,
        "AverageLatency": avg,
        "Jitter": jitter,
        "MinLatency": min_latency,
        "MaxLatency": max_latency
    }
