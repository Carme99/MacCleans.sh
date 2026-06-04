# Your First Cleanup

A 30-second walkthrough of running MacCleans for the first time. You'll preview what it would do, then commit.

## 1. Preview (no changes)

```bash
sudo Mac-Clean --dry-run
```

You'll see each of the 30 cleanup categories in turn. `--dry-run` is harmless — no files are touched. It also pre-flight checks disk space, sudo, iCloud config, and skips anything you've disabled.

```text
================================================
7. Browser Caches (Chrome, Firefox, Edge)
================================================
Chrome cache: 1.2 GB
Firefox cache: 480 MB
```

## 2. Read the output

Each section is formatted like:

If a section says `Skipping: ...` or `[skip]`, that's because of one of:
- `--skip-X` on the command line
- `SKIP_X=true` in your config file
- A safety gate (Photos running, iCloud Drive requires `--force`, etc.)

## 3. Run for real

When you're happy with the preview:

```bash
sudo Mac-Clean --yes
```

`--yes` skips the final confirmation prompt. The script will:
1. Re-pre-flight (in case anything changed since `--dry-run`)
2. Acquire its lock file (prevents parallel runs)
3. Walk every category
4. Print a summary: total bytes freed, categories processed, categories skipped
5. Optionally emit JSON if you passed `--json`

## 4. Inspect the result

```bash
sudo Mac-Clean --dry-run --json | jq '.results, .results.space_freed'
```

Sample `--json` output:

```json
{
  "version": "5.5.2",
  "timestamp": "2026-06-04T17:00:00Z",
  "dry_run": true,
  "results": {
    "categories": {
      "processed": ["Time Machine Local Snapshots", "Homebrew Cache"],
      "skipped": []
    },
    "disk_usage": { "before": 480000000000, "after": null },
    "space_freed": { "bytes": 0, "human": "0 B" }
  }
}
```

(`disk_usage.after` is `null` in dry-run because we don't measure after — the disk isn't actually changed.)

## Next

- Want to skip a category permanently? [how-to/configure.md](../how-to/configure.md)
- Want to see every flag? [reference/commands.md](../reference/commands.md)
- Want to schedule it? [how-to/automate.md](../how-to/automate.md)
