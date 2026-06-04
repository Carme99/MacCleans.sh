# Config File Reference

Every key in `maccleans.conf.example` (the source of truth), with default and type. Place this file at `~/.maccleans.conf` or `~/.config/maccleans/config`.

## File location

| Path | Used when |
|---|---|
| `~/.maccleans.conf` | If it exists |
| `~/.config/maccleans/config` | If the above doesn't exist (XDG-style) |
| `${XDG_CONFIG_HOME}/maccleans/config` | If `$XDG_CONFIG_HOME` is set and the above don't exist |

CLI flags override config values. See [how-to/configure.md](../how-to/configure.md) for the precedence chain.

## Boolean flags (`true` / `false`)

| Key | Default | Effect |
|---|---|---|
| `DRY_RUN` | `false` | Preview only — no files deleted. Equivalent to `--dry-run`. |
| `AUTO_YES` | `false` | Skip the final confirmation prompt. Equivalent to `--yes`. |
| `FORCE` | `false` | Skip ALL confirmation prompts (Xcode, iOS Backups, etc.). Equivalent to `--force`. **Dangerous.** |
| `QUIET` | `false` | Minimal output. Equivalent to `--quiet`. |
| `NO_COLOR` | `false` | Disable ANSI colors. Equivalent to `--no-color`. |
| `INTERACTIVE` | `false` | Open the category picker. Equivalent to `--interactive`. |
| `JSON_OUTPUT` | `false` | Emit JSON at the end. Equivalent to `--json`. |
| `UPDATE` | `false` | Run `brew update` first. Equivalent to `--update`. |
| `VERBOSE` | `false` | Verbose debug output. Equivalent to `--verbose`. |
| `SKIP_SNAPSHOTS` | `false` | Skip Time Machine local snapshots. |
| `SKIP_HOMEBREW` | `false` | Skip Homebrew cache. |
| `SKIP_SPOTIFY` | `false` | Skip Spotify cache (3a). |
| `SKIP_CLAUDE` | `false` | Skip Claude Desktop cache (3b). |
| `SKIP_XCODE` | `false` | Skip Xcode derived data. |
| `SKIP_BROWSERS` | `false` | Skip Chrome / Firefox / Edge caches. |
| `SKIP_NPM` | `false` | Skip npm / yarn caches. |
| `SKIP_PIP` | `false` | Skip Python pip cache. |
| `SKIP_TRASH` | `false` | Skip emptying the trash. |
| `SKIP_DSSTORE` | `false` | Skip `.DS_Store` cleanup. |
| `SKIP_DOCKER` | `false` | Skip Docker cache prune. |
| `SKIP_SIMULATOR` | `false` | Skip iOS Simulator data. |
| `SKIP_MAIL` | `false` | Skip Mail app cache. |
| `SKIP_SIRI_TTS` | `false` | Skip Siri TTS cache. |
| `SKIP_ICLOUD_MAIL` | `false` | Skip iCloud Mail cache. |
| `SKIP_PHOTOS_LIBRARY` | `false` | Skip Photos Library cache. |
| `SKIP_ICLOUD_DRIVE` | `false` | Skip iCloud Drive offline files. |
| `SKIP_QUICKLOOK` | `false` | Skip QuickLook thumbnail cache. |
| `SKIP_DIAGNOSTICS` | `false` | Skip Apple diagnostic reports. |
| `SKIP_IOS_BACKUPS` | `false` | Skip iOS device backups (requires `--force` separately to actually delete). |
| `SKIP_IOS_UPDATES` | `false` | Skip `.ipsw` firmware files. |
| `SKIP_COCOAPODS` | `false` | Skip CocoaPods cache. |
| `SKIP_GRADLE` | `false` | Skip Gradle cache. |
| `SKIP_GO` | `false` | Skip Go module cache. |
| `SKIP_BUN` | `false` | Skip Bun cache. |
| `SKIP_PNPM` | `false` | Skip pnpm store. |
| `SKIP_SYSTEM_TMP` | `true` | Skip `/tmp` and `/var/tmp`. **Default-on** for safety; opt in with `--clean-system-tmp` or set `SKIP_SYSTEM_TMP=false`. |

## String values

| Key | Default | Effect |
|---|---|---|
| `PROFILE` | (empty) | One of `conservative`, `developer`, `aggressive`, `minimal`. Sets a default skip list. See [how-to/profiles.md](../how-to/profiles.md). |
| `PHOTOS_LIBRARY_NAME` | (empty) | Restrict Photos cleanup to one library (e.g. `Vacation 2024`) or `all` for all libraries. Path-traversal characters rejected. |

## Numeric values

| Key | Default | Effect |
|---|---|---|
| `THRESHOLD` | `0` | Only run if disk usage exceeds this percent (0-100). Equivalent to `--threshold N`. |

## Force flags (rarely used)

These exist to bypass per-operation safety gates without enabling global `--force`. Most users will not set these.

| Key | Default | Effect |
|---|---|---|
| `FORCE_XCODE` | `false` | Allow Xcode derived data deletion without `--force`. |
| `FORCE_TRASH` | `false` | Allow trash emptying without `--force`. |
| `FORCE_ICLOUD_DRIVE` | `false` | Allow iCloud Drive offline files deletion (bypasses sync). |
| `FORCE_IOS_BACKUPS` | `false` | Allow iOS device backups deletion (requires iCloud backup enabled). |

## Environment variables

MacCleans also reads:

| Variable | Effect |
|---|---|
| `NO_COLOR` | Same as the config key, takes precedence. Standard convention. |
| `XDG_CONFIG_HOME` | Where the XDG-style config file lives. |

## Example

```ini
# Always preview first; require explicit confirm
DRY_RUN=false
AUTO_YES=false

# Skip development caches (Xcode, iOS Sim)
SKIP_XCODE=true
SKIP_SIMULATOR=true

# Run only when disk is >85% full
THRESHOLD=85

# Limit Photos cleanup to one library
PHOTOS_LIBRARY_NAME=Vacation 2024
```

For the precedence chain (CLI > env > config > defaults), see [how-to/configure.md](../how-to/configure.md).
