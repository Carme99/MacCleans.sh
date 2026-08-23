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
| Browser Testing Tool Caches | 500MB-2GB | Low | `--skip-browser-tools` |
| Crash Reports | 100MB-1GB | Low | `--skip-crash-reports` |
| User Tool Caches | 500MB-2GB | Low | `--skip-user-tool-caches` |
| Xcode Archives | 5-20GB | High | `--skip-xcode-archives` |
| JVM Build Caches | 500MB-5GB | Medium | `--skip-jvm` |
| JetBrains IDE Caches | 1-10GB | High | `--skip-jetbrains` |
| Cargo Registry Cache | 500MB-5GB | Low | `--skip-cargo` |
| NuGet Package Cache | 500MB-5GB | Medium | `--skip-nuget` |
| VS Code Cache | 200MB-2GB | Medium | `--skip-vscode` |
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

**More info:** See [Xcode Derived Data Guide](../how-to/guides/xcode-derived-data.md)

```bash
# Skip Xcode
sudo Mac-Clean --yes --skip-xcode
```

### Docker

**Path:** `/var/lib/docker` (system) and `~/Library/Containers/com.docker.docker` (app)

**Typical Size:** 1-20GB

**What it does:** Removes Docker containers and images. Named volumes and build cache are preserved.

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

**Path:** `~/Library/Caches/com.anthropic.claudefordesktop.ShipIt`

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

**Path:** `~/Library/CloudStorage/iCloud Drive*` (iCloud Drive folders under CloudStorage)

**Typical Size:** Variable

**What it does:** iCloud Drive files downloaded for offline use.

**Risk:** High - these are your actual files

**Warning:** Best-effort sync check before deletion (looks for `.icloud` placeholders, `Conflict*` files, and recent mtimes). Local-only or in-progress uploads can still be lost. iCloud Drive content on the server is unaffected for files that were fully synced at deletion time. Will refuse to run if `~/Library/CloudStorage` itself is a symlink.

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

### Browser Testing Tool Caches

**Path:** `~/.cache/puppeteer`, `~/.cache/selenium`

**Typical Size:** 500MB-2GB (often 1.5GB+ on a dev machine that has run Puppeteer/Selenium tests)

**What it does:** Puppeteer and Selenium both download full browser binaries (Chrome, headless Chrome, Firefox) into `~/.cache`. The next test run re-downloads whatever it needs.

**Note:** Covers the *cache* directories only. Browser installations in `/Applications` or via Homebrew are not touched.

**Risk:** Low - browsers are re-downloaded on the next test run, no user data is lost.

```bash
# Skip browser testing tool caches
sudo Mac-Clean --yes --skip-browser-tools
```

---

### Crash Reports

**Paths:** `~/Library/Logs/CrashReporter`, `~/Library/Application Support/CrashReporter`

**Typical Size:** 100MB-1GB (varies wildly; can be 0 on machines that don't crash)

**What it does:** macOS writes per-app crash dumps (`.crash`, `.ips`, `.diag`) to these locations whenever a process dies unexpectedly. MacCleans deletes dumps **older than 7 days**, so recent crashes stay available for "report a bug to vendor" workflows.

**Risk:** Low - older crash dumps are rarely useful and take up substantial space.

```bash
# Skip crash reports cleanup
sudo Mac-Clean --yes --skip-crash-reports
```

---

### User Tool Caches

**Paths:** `~/.cache/uv`, `~/.cache/giget`, `~/.cache/opencode`, `~/.cache/opencode-agent-skills`, `~/.cache/powershell`, `~/.cache/gh`, `~/.cache/starship`

**Typical Size:** 500MB-2GB (depends heavily on which CLI tools you use)

**What it does:** Modern CLI tools write their own caches to `~/.cache`:
- `uv` — downloaded Python packages (similar in spirit to the existing pip cache category #10, but in a different directory)
- `giget` — git-template downloads (used by Nuxt, Vite, and other JS toolchains)
- `opencode` and `opencode-agent-skills` — AI code editor's internal caches
- `powershell` — PowerShell module cache
- `gh` — GitHub CLI's API response cache
- `starship` — prompt configuration cache

**Note:** All of these are redownloaded on demand. `uv` and `giget` in particular can be 500MB+ each after a few weeks of use.

**Risk:** Low - none of these contain user data. Tools redownload what they need on the next invocation.

```bash
# Skip user tool caches
sudo Mac-Clean --yes --skip-user-tool-caches
```

---

### Xcode Archives

**Path:** `~/Library/Developer/Xcode/Archives`

**Typical Size:** 5-20GB on a Mac with any iOS/macOS development history

**What it does:** Deletes archived app builds (`.xcarchive` bundles). Each archive holds a release build plus its dSYMs.

**What it doesn't do:** Unlike DerivedData, archives are NOT regenerated. Recovery requires a backup.

**Risk:** High - release builds and debug symbols cannot be re-created once deleted

**When to skip:** Unless you are certain you won't need any archived builds

**Requires:** `--force-xcode` to delete without the interactive prompt (same gate as Xcode Derived Data)

```bash
# Skip Xcode Archives
sudo Mac-Clean --yes --skip-xcode-archives
```

---

### Cargo Registry Cache

**Paths:** `~/.cargo/registry/cache`, `~/.cargo/registry/src`

**Typical Size:** High — 500MB-5GB on an active Rust machine (`src/` alone often dwarfs `cache/`)

**What it does:** Cargo keeps every downloaded `.crate` archive in `registry/cache/` and the extracted sources for every dependency ever built in `registry/src/`. Both grow forever and are never pruned by Cargo itself.

**What it doesn't delete:** The registry index (`~/.cargo/registry/index`), installed binaries (`~/.cargo/bin`), `~/.cargo/config.toml`, and anything under `~/.rustup`.

**Risk:** Low - crates re-download from crates.io and re-extract on the next `cargo build`. The first build after cleaning recompiles from scratch (slow once), then incremental caching resumes as normal.

```bash
# Skip Cargo registry cache
sudo Mac-Clean --yes --skip-cargo
```

---

### JVM Build Caches

**Paths:** `~/.m2/repository` (Maven), `~/.ivy2/cache` (Ivy), `~/.sbt/boot` (sbt)

**Typical Size:** 500MB-5GB

**What it does:** Deletes downloaded Maven artifacts and dependencies, Ivy-resolved modules, and the sbt boot directory. Everything is re-downloaded from Maven Central or your configured Ivy repositories on the next build; sbt re-populates its boot directory on the next launch.

**Note:** Gradle is covered separately by category #24 Gradle Cache.

**Risk:** Medium - regenerates but first build after cleaning is slower

**When to skip:** If you work offline or on flaky internet

```bash
# Skip JVM build caches
sudo Mac-Clean --dry-run --skip-homebrew --skip-npm --skip-pip --skip-jvm
```

---

### JetBrains IDE Caches

**Paths:** `~/Library/Caches/JetBrains` (entire tree)

**Typical Size:** 1-10GB (High — per-version cache directories accumulate across IDE upgrades and are never cleaned up automatically)

**What it does:** Every JetBrains IDE (IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, RubyMine, PhpStorm, Android Studio, ...) writes per-version cache directories under `~/Library/Caches/JetBrains`. Old versions' caches survive upgrades indefinitely. MacCleans clears the whole Caches tree; the caches themselves (indexes, compiled output) rebuild on the next IDE launch.

**Note:** Strictly out of scope: `~/Library/Application Support/JetBrains` (IDE settings + installed plugins — deleting it loses your configuration), `~/Library/Logs/JetBrains`, and VS Code-style extension directories. Only the Caches tree is touched.

**Warning:** IDE Local History lives inside the Caches tree (`<product><version>/LocalHistory`) and is **permanently lost** when it is deleted — it does not rebuild. Your settings and plugins under `~/Library/Application Support/JetBrains` are unaffected.

**Risk:** High - the caches themselves rebuild on the next launch, but a first launch after clearing re-indexes every open project (5-30 minutes of CPU per project). Skip this category if you cannot afford the re-index time.

```bash
# Skip JetBrains IDE caches
sudo Mac-Clean --yes --skip-jetbrains
```

---

### NuGet Package Cache

**Path:** `~/.nuget/packages`

**Typical Size:** 500MB-5GB

**What it does:** Deletes the global-packages folder where NuGet stores downloaded `.nupkg` archives and their extracted contents. Packages are re-downloaded from nuget.org on the next `dotnet restore` or build.

**Risk:** Low-Medium - fully regenerates; the only cost is re-download time and bandwidth.

**When to skip:** If you work offline frequently

```bash
# Skip NuGet package cache
sudo Mac-Clean --yes --skip-nuget
```

---

### VS Code Cache

**Paths:**
- `~/Library/Application Support/Code/Cache`, `CachedData`, `Code Cache`, `GPUCache`
- `~/Library/Application Support/Code/Service Worker/CacheStorage`
- `~/Library/Caches/com.microsoft.VSCode`

**Typical Size:** 200MB-2GB

**What it does:** VS Code's regenerable caches: renderer bytecode caches, GPU cache, service-worker cache storage, and the macOS-level app cache. Everything rebuilds automatically on the next launch.

**What it doesn't delete:** Settings (`Code/User`), extensions (`~/.vscode`), and per-workspace state (`workspaceStorage`).

**Risk:** Medium - safe to delete, but the first launch afterwards is slower while caches rebuild

```bash
# Skip VS Code cache
sudo Mac-Clean --yes --skip-vscode
```

---

## Guides

For deeper understanding of specific categories:

| Guide | Category |
|-------|----------|
| [Xcode Derived Data](../how-to/guides/xcode-derived-data.md) | Xcode |
| [Docker Cache](../how-to/guides/docker-cache.md) | Docker |
| [Understanding Caches](../how-to/guides/understanding-macos-caches.md) | All caches |

---

<p align="center">

[Back to Documentation](../README.md) · [Profiles](../how-to/profiles.md) · [Command Reference](commands.md)

</p>
