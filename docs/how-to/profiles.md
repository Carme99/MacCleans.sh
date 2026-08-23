# Profiles

Profiles are presets that skip specific categories for different use cases.

## Quick Comparison

| Profile | Best For | Typical Recovery | Skips |
|---------|---------|---------------|-------|
| **Conservative** | Regular users | 5-15GB | Xcode, npm, pip, Docker, browsers, iOS Simulator, iOS Backups, iOS Updates |
| **Developer** | Xcode devs | 10-40GB | Xcode, iOS Backups |
| **Aggressive** | Maximum space | 15-100GB+ | Nothing |
| **Minimal** | Quick cleanup | 2-5GB | Xcode, npm, pip, Docker, browsers, Spotify, Claude, iOS Simulator, Mail, iOS Backups, iOS Updates |

> Skip lists above reflect the actual `load_profile()` switches in `clean-mac-space.sh`. If you change the code, update this table.

## Profile Details

### Conservative

Recommended for most users. Skips development-related caches plus the iOS categories.

**Command:**
```bash
sudo Mac-Clean --profile conservative --yes
```

**Skips:**
- Xcode Derived Data
- npm / Yarn / pnpm
- pip
- Docker
- Browser caches
- iOS Simulator
- iOS Device Backups
- iOS/iPadOS Update Files (`.ipsw`)

**Good for:** Users who don't develop software and want a safe-but-thorough cleanup.

---

### Developer

For software developers who use Xcode. Skips Xcode Derived Data (to keep build times fast) and iOS Device Backups (which are large and slow to re-download from iCloud).

**Command:**
```bash
sudo Mac-Clean --profile developer --yes
```

**Skips:**
- Xcode Derived Data (to avoid 5-30 minute rebuilds)
- iOS Device Backups

**Cleans:**
- npm / Yarn / pnpm
- pip
- Docker
- Browser caches
- iOS Simulator
- Dev-tool caches (JVM build, JetBrains IDEs, Cargo, NuGet, VS Code)
- Browser testing tool caches
- iOS/iPadOS Update Files
- Everything else

**Good for:** Developers who use Xcode regularly and have iCloud Backup enabled (so iOS backups can be re-downloaded if needed).

---

### Aggressive

Cleans everything, no safety nets.

**Command:**
```bash
sudo Mac-Clean --profile aggressive --yes
```

**Skips:** Nothing

**Good for:** When you urgently need disk space.

**Warning:** This will delete Xcode Derived Data, which means your next build will take 5-30 minutes longer. iOS Device Backups are also deleted.

---

### Minimal

Conservative cleanup of the safest categories only. Despite the name, this skips *more* than Conservative — it's the "least destructive" preset.

**Command:**
```bash
sudo Mac-Clean --profile minimal --yes
```

**Skips:**
- Xcode Derived Data
- npm / Yarn / pnpm
- pip
- Docker
- Browser caches
- Spotify cache
- Claude cache
- iOS Simulator
- Mail attachments cache
- iOS Device Backups
- iOS/iPadOS Update Files (`.ipsw`)

**Cleans:**
- System caches
- Old log files
- User cache files
- Trash
- `.DS_Store` files

**Good for:** Regular maintenance when you want to leave application caches and dev tools alone.

---

## When to Use Which

```
Need space urgently?
    │
    ├── Yes → Aggressive
    │
    └── No
        │
        ├── Xcode developer?
        │       │
        │       ├── Yes → Developer
        │       │
        │       └── No → Conservative
        │
        └── Quick maintenance?
                │
                └── Yes → Minimal
                        │
                        └── No → Conservative
```

## Combining Profiles with Skip Flags

Profiles can be combined with `--skip-X` flags for custom cleanup:

```bash
# Developer profile but keep npm cache
sudo Mac-Clean --profile developer --skip-npm --yes

# Aggressive but keep Docker
sudo Mac-Clean --profile aggressive --skip-docker --yes

# Conservative but also skip browsers
sudo Mac-Clean --profile conservative --skip-browsers --yes
```

## Creating Custom Profiles

Create a config file for your custom profile:

```bash
# ~/.maccleans.conf
SKIP_XCODE=true
SKIP_NPM=false
SKIP_PIP=false
SKIP_DOCKER=true
SKIP_BROWSERS=true
AUTO_YES=true
THRESHOLD=80
```

Then run:
```bash
sudo Mac-Clean --yes
```

See [Configuration](configure.md) for full details.

## Profile vs Skip Flags

| Approach | Use Case |
|---------|----------|
| `--profile conservative` | Quick preset for regular users |
| `--profile developer` | Quick preset for Xcode developers |
| `--skip-xcode --skip-docker` | Fine-grained control |
| Config file | Persistent custom settings |

## Recovery Estimates by Profile

These are typical values - your mileage may vary.

| Profile | Casual User | Web Dev | iOS Dev | Docker Heavy |
|---------|-----------|---------|---------|---------------|
| Conservative | 5-10GB | 10-20GB | 15-30GB | 20-40GB |
| Developer | 10-15GB | 15-25GB | 20-50GB | 25-60GB |
| Aggressive | 15-25GB | 20-40GB | 30-80GB | 40-100GB+ |
| Minimal | 1-3GB | 2-5GB | 3-8GB | 5-10GB |

---

<p align="center">

[Back to Documentation](../README.md) · [All Categories](../reference/categories.md) · [Command Reference](../reference/commands.md)

</p>
