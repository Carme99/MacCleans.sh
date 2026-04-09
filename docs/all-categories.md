# All Categories

Complete reference of all cleanup categories in MacCleans.

## Summary Table

| Category | Typical Size | Risk | Skip Flag |
|----------|-------------|------|-----------|
| Xcode Derived Data | 5-50GB | Medium | `--skip-xcode` |
| Docker | 1-20GB | Low | `--skip-docker` |
| Homebrew Cache | 1-5GB | Low | `--skip-homebrew` |
| npm / Yarn / pnpm | 500MB-5GB | Low | `--skip-npm` |
| pip Cache | 100MB-2GB | Low | `--skip-pip` |
| iOS Simulator | 1-10GB | Medium | `--skip-simulator` |
| Browser Caches | 1-5GB | Low | `--skip-browsers` |
| Time Machine | 10-100GB | Medium | `--skip-snapshots` |
| Trash | Variable | Low | `--skip-trash` |
| .DS_Store | 100MB-2GB | Low | `--skip-dsstore` |
| Spotify | 100MB-1GB | Low | `--skip-spotify` |
| Claude | 100MB-1GB | Low | `--skip-claude` |
| Mail | 100MB-1GB | Low | `--skip-mail` |
| Siri TTS | 100MB-500MB | Low | `--skip-siri-tts` |
| iCloud Mail | 100MB-1GB | Low | `--skip-icloud-mail` |
| iCloud Drive | Variable | High | `--skip-icloud-drive` |
| QuickLook | 100MB-1GB | Low | `--skip-quicklook` |
| Diagnostics | 100MB-1GB | Low | `--skip-diagnostics` |
| iOS Backups | 1-10GB | Medium | `--skip-ios-backups` |
| iOS Updates | 1-5GB | Low | `--skip-ios-updates` |
| CocoaPods | 100MB-1GB | Low | `--skip-cocoapods` |
| Gradle | 100MB-2GB | Low | `--skip-gradle` |
| Go Modules | 100MB-1GB | Low | `--skip-go` |
| Bun | 100MB-500MB | Low | `--skip-bun` |
| Photos Library | 500MB-5GB | Low | `--skip-photos-library` |
| System Logs | 100MB-1GB | Low | (always safe) |
| User Logs | 100MB-500MB | Low | (always safe) |
| System Cache | 100MB-1GB | Low | (always safe) |
| User Cache | 100MB-1GB | Low | (always safe) |

## Risk Levels

| Level | Meaning |
|-------|---------|
| **Low** | Safe to delete, no side effects |
| **Medium** | Deletes data that regenerates, but may take time |
| **High** | Could cause data loss if you don't understand it |

---

## Development

### Xcode Derived Data

**Path:** `~/Library/Developer/Xcode/DerivedData`

**Typical Size:** 5-50GB

**What it does:** Contains build intermediates, indexes, and debug symbols for Xcode projects.

**Risk:** Medium - next build will take longer (5-30 minutes)

**When to skip:** If you're an active Xcode developer

**More info:** See [Xcode Derived Data Guide](guides/xcode-derived-data.md)

```bash
# Skip Xcode
sudo Mac-Clean --yes --skip-xcode
```

### Docker

**Path:** `/var/lib/docker` (system) and `~/Library/Containers/com.docker.docker` (app)

**Typical Size:** 1-20GB

**What it does:** Removes Docker containers, images, volumes, and build cache.

**Risk:** Low - containers can be rebuilt from Dockerfiles

**When to skip:** If you need Docker containers running

```bash
# Skip Docker
sudo Mac-Clean --yes --skip-docker
```

### Homebrew Cache

**Path:** `~/Library/Caches/Homebrew`

**Typical Size:** 1-5GB

**What it does:** Downloads cached by Homebrew during installations.

**Risk:** Low - downloads regenerate on next install

```bash
# Skip Homebrew
sudo Mac-Clean --yes --skip-homebrew
```

### npm / Yarn / pnpm

**Paths:**
- npm: `~/.npm`
- Yarn: `~/.yarn/cache`
- pnpm: `~/.pnpm-store`

**Typical Size:** 500MB-5GB

**What it does:** Package manager caches for Node.js development.

**Risk:** Low - packages redownload as needed

```bash
# Skip npm/yarn/pnpm
sudo Mac-Clean --yes --skip-npm
```

### pip Cache

**Path:** `~/Library/Caches/pip`

**Typical Size:** 100MB-2GB

**What it does:** Python package index cache.

**Risk:** Low - packages redownload as needed

```bash
# Skip pip
sudo Mac-Clean --yes --skip-pip
```

### iOS Simulator

**Path:** `~/Library/Developer/CoreSimulator`

**Typical Size:** 1-10GB

**What it does:** iOS simulator devices and data.

**Risk:** Medium - simulators take time to reinstall

**When to skip:** If you develop for iOS

```bash
# Skip Simulator
sudo Mac-Clean --yes --skip-simulator
```

### CocoaPods

**Path:** `~/Library/Caches/CocoaPods`

**Typical Size:** 100MB-1GB

**What it does:** CocoaPods package cache.

**Risk:** Low - pods redownload as needed

```bash
# Skip CocoaPods
sudo Mac-Clean --yes --skip-cocoapods
```

### Gradle

**Path:** `~/.gradle/caches`

**Typical Size:** 100MB-2GB

**What it does:** Gradle build cache and dependencies.

**Risk:** Low - caches rebuild automatically

```bash
# Skip Gradle
sudo Mac-Clean --yes --skip-gradle
```

### Go Modules

**Path:** `~/go/pkg/mod`

**Typical Size:** 100MB-1GB

**What it does:** Go module cache.

**Risk:** Low - modules redownload as needed

```bash
# Skip Go
sudo Mac-Clean --yes --skip-go
```

### Bun

**Path:** `~/.bun/install/cache`

**Typical Size:** 100MB-500MB

**What it does:** Bun package manager cache.

**Risk:** Low - packages redownload as needed

```bash
# Skip Bun
sudo Mac-Clean --yes --skip-bun
```

---

## Browsers

### Browser Caches

**Paths:**
- Chrome: `~/Library/Caches/Google/Chrome`
- Firefox: `~/Library/Caches/Firefox`
- Edge: `~/Library/Caches/Microsoft Edge`

**Typical Size:** 1-5GB

**What it does:** Browser caches for web pages and assets.

**Risk:** Low - caches rebuild as you browse

**What it doesn't delete:** History, bookmarks, passwords, cookies

```bash
# Skip browsers
sudo Mac-Clean --yes --skip-browsers
```

---

## Applications

### Spotify

**Path:** `~/Library/Caches/com.spotify.client`

**Typical Size:** 100MB-1GB

**What it does:** Spotify application cache.

**Risk:** Low - cache rebuilds as you use Spotify

```bash
# Skip Spotify
sudo Mac-Clean --yes --skip-spotify
```

### Claude

**Path:** `~/Library/Caches/Claude`

**Typical Size:** 100MB-1GB

**What it does:** Claude desktop application cache.

**Risk:** Low - cache rebuilds automatically

```bash
# Skip Claude
sudo Mac-Clean --yes --skip-claude
```

### Mail

**Path:** `~/Library/Mail` (attachments cache)

**Typical Size:** 100MB-1GB

**What it does:** Downloaded email attachments.

**Risk:** Low - attachments re-download as needed

```bash
# Skip Mail
sudo Mac-Clean --yes --skip-mail
```

---

## System

### Time Machine Local Snapshots

**Command:** `tmutil deletelocalsnapshots`

**Typical Size:** 10-100GB

**What it does:** Local Time Machine snapshots stored on disk.

**Risk:** Medium - these are backup points

**When to skip:** If you need local backup restore points

**Requires:** `--force` flag to actually delete

```bash
# Skip snapshots
sudo Mac-Clean --yes --skip-snapshots
```

### System Logs

**Path:** `/var/log` and `~/Library/Logs`

**Typical Size:** 100MB-1GB

**What it does:** System and application logs.

**Risk:** Low - logs regenerate

### User Diagnostics

**Path:** `~/Library/Logs/DiagnosticReports`

**Typical Size:** 100MB-1GB

**What it does:** Crash reports and diagnostic data.

**Risk:** Low - diagnostic data regenerates

```bash
# Skip diagnostics
sudo Mac-Clean --yes --skip-diagnostics
```

---

## Cloud Storage

### iCloud Drive

**Path:** `~/Library/Mobile Documents` (iCloud offline files)

**Typical Size:** Variable

**What it does:** iCloud Drive files downloaded for offline use.

**Risk:** High - these are your actual files

**Warning:** Only deletes files that are fully synced and available online. iCloud Drive remains intact.

**When to skip:** If you work offline frequently

```bash
# Skip iCloud Drive
sudo Mac-Clean --yes --skip-icloud-drive
```

### iCloud Mail

**Path:** `~/Library/Mail/V2`

**Typical Size:** 100MB-1GB

**What it does:** iCloud mail cache.

**Risk:** Low - mail redownloads as needed

```bash
# Skip iCloud Mail
sudo Mac-Clean --yes --skip-icloud-mail
```

---

## Utilities

### Trash

**Paths:**
- User trash: `~/.Trash`
- System trash: `/Volumes/*/.Trashes`

**Typical Size:** Variable

**What it does:** Permanently empties the Trash bin.

**Risk:** Low - files in trash are already "deleted"

```bash
# Skip trash
sudo Mac-Clean --yes --skip-trash
```

### .DS_Store

**Path:** Scans entire home directory

**Typical Size:** 100MB-2GB

**What it does:** Removes macOS Finder metadata files.

**Risk:** Low - Finder recreates these

```bash
# Skip DS_Store
sudo Mac-Clean --yes --skip-dsstore
```

### QuickLook

**Path:** `~/Library/Caches/com.apple.QuickLook`

**Typical Size:** 100MB-1GB

**What it does:** QuickLook thumbnail cache.

**Risk:** Low - thumbnails rebuild

```bash
# Skip QuickLook
sudo Mac-Clean --yes --skip-quicklook
```

### Siri TTS

**Path:** `~/Library/Caches/com.apple.Siri.safaris`

**Typical Size:** 100MB-500MB

**What it does:** Siri voice synthesis cache.

**Risk:** Low - cache rebuilds

```bash
# Skip Siri TTS
sudo Mac-Clean --yes --skip-siri-tts
```

---

## iOS Device Management

### iOS Device Backups

**Path:** `~/Library/Application Support/MobileSync/Backup`

**Typical Size:** 1-10GB

**What it does:** Local iPhone/iPad backups stored on Mac.

**Risk:** Medium - you may need these to restore a device

**When to skip:** If you need backup data to restore a device

```bash
# Skip iOS backups
sudo Mac-Clean --yes --skip-ios-backups
```

### iOS Software Updates

**Path:** `~/Library/Updates` and `/Library/Apple/Software Update`

**Typical Size:** 1-5GB

**What it does:** Downloaded iOS and macOS update files (.ipsw).

**Risk:** Low - updates re-download if needed

```bash
# Skip iOS updates
sudo Mac-Clean --yes --skip-ios-updates
```

### Photos Library

**Path:** `~/Pictures/Photos Library.photoslibrary`

**Typical Size:** 500MB-5GB (cache portions only)

**What it does:** Photos library cache (thumbnails, previews, duplicates).

**Note:** Only cleans cache portions, not your actual photos or videos.

**Risk:** Low - photos remain intact

```bash
# Skip Photos
sudo Mac-Clean --yes --skip-photos-library
```

---

## Guides

For deeper understanding of specific categories:

| Guide | Category |
|-------|----------|
| [Xcode Derived Data](guides/xcode-derived-data.md) | Xcode |
| [Docker Cache](guides/docker-cache.md) | Docker |
| [Understanding Caches](guides/understanding-caches.md) | All caches |

---

<p align="center">

[Back to Documentation](index.md) · [Profiles](profiles.md) · [Command Reference](command-reference.md)

</p>
