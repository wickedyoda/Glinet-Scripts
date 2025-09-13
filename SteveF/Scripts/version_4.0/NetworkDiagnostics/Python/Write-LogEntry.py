import datetime
from pathlib import Path
from colorama import init, Fore, Style

# Initialize colorama
init(autoreset=True)

# Map PowerShell-style color names to colorama
COLOR_MAP = {
    "Gray": Fore.LIGHTBLACK_EX,
    "Red": Fore.RED,
    "Green": Fore.GREEN,
    "Yellow": Fore.YELLOW,
    "Blue": Fore.BLUE,
    "Cyan": Fore.CYAN,
    "Magenta": Fore.MAGENTA,
    "White": Fore.WHITE
}

def write_log_entry(message: str, log_path: str, color: str = "Gray"):
    timestamp = datetime.datetime.now().strftime("%H:%M:%S")
    entry = f"{timestamp} {message}"

    # Print to console with color
    console_color = COLOR_MAP.get(color, Fore.LIGHTBLACK_EX)
    print(f"{console_color}{entry}{Style.RESET_ALL}")

    # Append to log file
    Path(log_path).parent.mkdir(parents=True, exist_ok=True)
    with open(log_path, "a", encoding="utf-8") as log_file:
        log_file.write(entry + "\n")
