# Error Codes

MacCleans uses exit codes to indicate success or failure.

## Exit Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | Success | Cleanup completed successfully |
| 1 | General Error | Something went wrong |
| 2 | Permission Denied | Needs sudo/root access |
| 3 | Invalid Arguments | Invalid command-line arguments |
| 4 | Config Validation Failed | Configuration file has invalid values |
| 5 | Keyboard Interrupted | User cancelled with Ctrl+C |
| 6 | Disk Space Sufficient | Threshold not met, nothing cleaned |

## Code Details

### 0 - Success

The cleanup completed without errors. All requested categories were processed.

### 1 - General Error

An unexpected error occurred. Check the output for details. If the problem persists, please [open an issue](https://github.com/Carme99/MacCleans.sh/issues).

### 2 - Permission Denied

MacCleans requires sudo privileges to clean system directories. Run with:

```bash
sudo Mac-Clean
```

### 3 - Invalid Arguments

One or more command-line arguments are invalid. Check the help:

```bash
Mac-Clean --help
```

### 4 - Config Validation Failed

Your configuration file has invalid values. Common causes:

- Boolean values must be exactly `true` or `false` (not `yes`, `no`, `1`, `0`)
- `THRESHOLD` must be between 0 and 100

See [Configuration](configuration.md#validation) for details.

### 5 - Keyboard Interrupted

You cancelled the operation with Ctrl+C. No changes were made.

### 6 - Disk Space Sufficient

The `--threshold` option is set and your disk usage is below the threshold. No cleanup was performed. This is not an error - it simply means cleanup wasn't needed.

## Using Exit Codes in Scripts

Check the exit code after running MacCleans:

```bash
sudo Mac-Clean --yes
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "Cleanup completed successfully"
elif [ $exit_code -eq 6 ]; then
    echo "Disk space sufficient, no cleanup needed"
else
    echo "Cleanup failed with exit code: $exit_code"
fi
```

## JSON Output with Exit Codes

When using `--json`, the exit code is included in the output:

```bash
sudo Mac-Clean --json --yes
echo "Exit code: $?"
```

## Common Issues

### "Permission denied" error (exit code 2)

**Cause:** Not running with sudo.

**Fix:**
```bash
sudo Mac-Clean
```

### "Configuration validation failed" (exit code 4)

**Cause:** Invalid value in config file.

**Fix:** Check your config file. Boolean values must be `true` or `false`, not `yes` or `no`.

### Script exits immediately (exit code 5)

**Cause:** Ctrl+C was pressed or process received SIGINT signal.

### Exit code 6 with threshold

**Cause:** Disk usage is below your threshold. This is normal behavior.

---

<p align="center">

[Back to Documentation](index.md) · [Troubleshooting](../troubleshooting.md) · [Command Reference](command-reference.md)

</p>
