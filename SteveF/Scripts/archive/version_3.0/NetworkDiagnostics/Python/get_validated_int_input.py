def get_validated_int(prompt, default, min_val, max_val, label):
    """
    Prompt the user for an integer input with validation and fallback to default.

    Args:
        prompt (str): The message to display to the user.
        default (int): The default value to use if input is invalid or empty.
        min_val (int): Minimum acceptable value.
        max_val (int): Maximum acceptable value.
        label (str): Label used in error messages.

    Returns:
        int: Validated integer input or default.
    """
    try:
        value = input(f"{prompt} (default: {default}): ").strip()
        if not value:
            return default
        value = int(value)
        if value < min_val or value > max_val:
            print(f"Invalid {label}. Must be between {min_val} and {max_val}. Using default: {default}")
            return default
        return value
    except ValueError:
        print(f"Invalid input. Using default {default}.")
        return default
        
