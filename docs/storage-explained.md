# Storage Explained

Understanding what MacCleans cleans and why your disk gets full.

## How macOS Uses Disk Space

### System Cache

macOS caches files to speed up operations. These caches are safe to clean:

| Cache Type | Location | Purpose |
|------------|----------|---------|
| System cache | `/Library/Caches` | OS-level caching |
| User cache | `~/Library/Caches` | App-level caching |
| XProtect | `/Library/Apple/System` | Security definitions |

### Derived Data

Xcode generates Derived Data when building projects. This can grow very large:

```
~/Library/Developer/Xcode/DerivedData/
├── Build/          # Compiled binaries
├── Index/          # Code search index
└── SourcePackages/ # Swift Package Manager
```

### Logs

macOS and apps write logs for debugging. These can accumulate:

| Log Type | Typical Size | Purpose |
|----------|--------------|---------|
| System logs | 1-5 GB | macOS debugging |
| App logs | 100 MB - 1 GB | Application debugging |
| Crash reports | 100 MB - 500 MB | Error tracking |

## Why Disks Fill Up

### Common Causes

1. **Xcode Derived Data** - Can reach 50+ GB for large projects
2. **Docker** - Images, containers, and volumes can use 20+ GB
3. **Homebrew** - Cached downloads can use 5-10 GB
4. **iOS Simulator** - Can reach 10+ GB with many simulators
5. **Browsers** - Cache can grow to 1-5 GB per browser
6. **npm/Yarn/pnpm** - node_modules and cache can reach 10+ GB
7. **Photos** - Thumbnails and edits cache can grow large

### Spotting the Culprits

Run with verbose output to see detailed sizes:

```bash
sudo Mac-Clean --dry-run --verbose
```

### Safe to Clean

MacCleans only removes files that:

- Are regenerated automatically when needed
- Do not contain personal data
- Are not critical for app function

### Never Cleaned

MacCleans never touches:

- Documents (`~/Documents`)
- Desktop files (`~/Desktop`)
- Downloads (`~/Downloads`)
- Photos library
- Email messages
- Browser bookmarks and passwords
- Application settings

## Cache Regeneration

Caches are regenerated when apps next need them. This means:

- **No apps will break** - they recreate caches as needed
- **First run may be slower** - cold cache means slower load
- **Space returns quickly** - caches rebuild over days/weeks

## Time Machine Local Snapshots

macOS creates local Time Machine snapshots when your backup drive is unavailable. These are:

- Stored in `/Volumes/TimeMachine*`
- Used for Time Machine restores
- Automatically deleted when space is needed
- Not the same as cloud backups

## Storage Management

### Built-in macOS Tools

1. **Apple Menu > About This Mac > Storage** - See usage breakdown
2. **System Settings > General > Storage** - Manage storage
3. **Disk Utility** - Repair and manage disks

### Third-Party Tools

| Tool | Purpose |
|------|---------|
| OmniDiskSweeper | Find large files |
| DaisyDisk | Visual disk map |
| CleanMyMac | Paid cleanup utility |

## SSD vs HDD

MacCleans works on both SSD and HDD. Benefits are greater on SSDs because:

- Free space improves wear levelling
- More free space helps TRIM
- Faster writes on free space

## Signs You Need to Clean

| Sign | Description |
|------|-------------|
| "Disk is almost full" alert | macOS warning |
| Apps won't update | Insufficient space |
| Slow file operations | Disk fragmentation |
| Can't install Xcode | Need more space |
| Photos import failing | Storage full |

## How Much Can You Reclaim?

Typical values for a developer Mac:

| Category | Size |
|----------|------|
| Xcode Derived Data | 10-50 GB |
| Docker | 5-30 GB |
| Homebrew | 2-10 GB |
| npm/Yarn | 2-15 GB |
| iOS Simulator | 3-15 GB |
| Browser cache | 1-5 GB |
| System cache | 1-5 GB |
| Logs | 500 MB - 3 GB |
| Trash | 1-10 GB |

Total potential: **30-150 GB** for a typical developer Mac.

---

<p align="center">

[Back to Documentation](index.md) · [All Categories](all-categories.md) · [Troubleshooting](troubleshooting.md)

</p>
