function Get-ValidatedIntInput {
    param (
        [string]$Prompt,
        [int]$Default,
        [int]$Min = 1,
        [int]$Max = 100,
        [string]$Label = "value"
    )

    $input = Read-Host "$Prompt (default: $Default)"

    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }

    if ([int]::TryParse($input, [ref]$null)) {
        $parsed = [int]$input
        if ($parsed -ge $Min -and $parsed -le $Max) {
            return $parsed
        }
    }

    return $Default
}
