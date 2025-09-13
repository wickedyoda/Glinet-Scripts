from colorama import init, Fore, Style
import datetime

init(autoreset=True)

def write_log_entry(message, logpath, color=None):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"

    # Write to log file
    with open(logpath, "a", encoding="utf-8") as f:
        f.write(entry + "\n")

    # Print to console with optional color
    if color:
        print(color + message + Style.RESET_ALL)
    else:
        print(message)
