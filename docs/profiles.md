# Profiles

Profiles are presets that skip specific categories for different use cases.

## Quick Comparison

| Profile | Best For | Typical Recovery | Skips |
|---------|---------|---------------|-------|
| **Conservative** | Regular users | 5-15GB | Xcode, npm, pip, Docker, browsers |
| **Developer** | Software devs | 10-40GB | Only Xcode |
| **Aggressive** | Maximum space | 15-100GB+ | Nothing |
| **Minimal** | Quick cleanup | 2-5GB | All app caches |

## Profile Details

### Conservative

Recommended for most users. Skips development-related caches.

**Command:**
```bash
sudo Mac-Clean --profile conservative --yes
```

**Skips:**
- Xcode Derived Data
- npm / Yarn / pnpm
- pip
- Docker
- iOS Simulator
- Browser caches

**Good for:** Users who don't develop software.

---

### Developer

For software developers who use Xcode. Skips only Xcode to avoid long rebuild times.

**Command:**
```bash
sudo Mac-Clean --profile developer --yes
```

**Skips:**
- Xcode Derived Data (to avoid 5-30 minute rebuilds)

**Cleans:**
- npm / Yarn / pnpm
- pip
- Docker
- Browser caches
- Everything else

**Good for:** Developers who use Xcode regularly.

---

### Aggressive

Cleans everything, no safety nets.

**Command:**
```bash
sudo Mac-Clean --profile aggressive --yes
```

**Skips:** Nothing

**Good for:** When you urgently need disk space.

**Warning:** This will delete Xcode Derived Data, which means your next build will take 5-30 minutes longer.

---

### Minimal

Quick cleanup of only the safest categories.

**Command:**
```bash
sudo Mac-Clean --profile minimal --yes
```

**Skips:**
- All application caches
- Development tools
- System logs

**Cleans:**
- System caches
- Logs
- Trash
- .DS_Store

**Good for:** Regular maintenance when you want minimal impact.

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

See [Configuration](configuration.md) for full details.

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

[Back to Documentation](index.md) · [All Categories](all-categories.md) · [Command Reference](command-reference.md)

</p>
