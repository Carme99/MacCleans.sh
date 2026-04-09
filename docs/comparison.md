# Comparison with Other Tools

[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Tested](https://img.shields.io/badge/Tested%20on-26.4-green.svg)]()

MacCleans.sh vs other popular macOS cleanup and disk management tools.

## Quick Comparison

| Feature | MacCleans.sh | CleanMyMac X | CCleaner | DaisyDisk | OnyX |
|---------|--------------|--------------|-----------|-----------|------|
| **Price** | Free | £25/yr | £25/yr | £10 | Free |
| **Open Source** | Yes | No | No | No | Partial |
| **CLI / Scriptable** | Yes | No | Partial | No | No |
| **macOS Native** | Yes | No | No | No | Yes |
| **Privacy** | 100% Local | Cloud | Cloud | Local | Local |

## Detailed Comparison

### MacCleans.sh

**Pros:**
- Completely free and open-source
- Command-line interface for automation
- No cloud features or telemetry
- Transparent - audit the code yourself
- Lightweight - no extra dependencies
- Actively maintained on GitHub

**Cons:**
- No GUI (terminal required)
- No malware scanning
- No app uninstaller
- Manual updates required

**Best for:** Developers, power users, and anyone comfortable with the command line who wants automated, transparent cleanup.

---

### CleanMyMac X

**Pros:**
- Full GUI with visual interface
- App uninstaller with leftover removal
- Malware detection
- One-click optimization
- Professional support

**Cons:**
- Expensive subscription model
- Closed source - can't audit
- Requires installation
- May be overkill for simple needs

**Best for:** Users who prefer a visual interface and are willing to pay for convenience.

---

### CCleaner (Piriform)

**Pros:**
- Familiar brand
- Cross-platform (Windows too)
- Browser cleanup
- Registry cleaning (Windows)

**Cons:**
- Subscription model
- Mixed privacy history
- Not designed for macOS specifically
- Limited macOS features

**Best for:** Users who want cross-platform familiarity.

---

### DaisyDisk

**Pros:**
- Beautiful visual disk map
- Helps find large files manually
- Quick Look integration

**Cons:**
- Only analyzes, doesn't clean
- Paid app
- No automation

**Best for:** Finding specific large files manually. Use with MacCleans for complete solution.

**Best combo:** DaisyDisk to find what to clean → MacCleans to clean it automatically.

---

### OnyX

**Pros:**
- Free
- Comprehensive system utility
- Customizable automation
- No installation needed

**Cons:**
- Complex interface
- Can be intimidating
- Some features require disabling SIP
- No official support

**Best for:** Advanced users who want deep system control.

---

## When to Use What

| Scenario | Recommended Tool |
|----------|------------------|
| Regular automated cleanup | MacCleans.sh |
| Emergency disk space | MacCleans.sh --profile aggressive |
| Find large files visually | DaisyDisk |
| App uninstaller + cleanup | CleanMyMac X |
| Deep system maintenance | OnyX |
| One-time deep clean | CleanMyMac X |
| CI/CD runner maintenance | MacCleans.sh |

## Can You Use Multiple?

Yes! Many users combine tools:

1. **MacCleans + DaisyDisk**: MacCleans handles automated cleanup, DaisyDisk helps find specific large files
2. **MacCleans + CleanMyMac**: MacCleans for regular CLI cleanup, CleanMyMac for occasional deep cleaning
3. **All of them**: Just don't run them simultaneously

## Why MacCleans Exists

MacCleans.sh was created to fill a gap:
- Free tools were either too simple or required payment
- CLI automation was missing from most options
- Privacy-focused tools didn't exist
- Developers needed scriptable cleanup for CI/CD

It's not about replacing commercial tools - it's about giving users choice and transparency.

## Related Projects

MacCleans.sh draws inspiration from several open-source projects:

- **[mac-cleanup](https://github.com/mac-cleanup/mac-cleanup-sh)** (MIT License) - A popular shell-based macOS cleanup script that helped inspire several cleanup categories in MacCleans.sh. The CocoaPods, Gradle, Go, Bun, and pnpm cleanup modules were particularly influenced by their approach.

Both projects aim to provide free, transparent, and scriptable cleanup for macOS - we encourage users to explore both!

---

**Related:**
- [FAQ](faq.md) - Common questions
- [Command Reference](command-reference.md) - Full command reference
- [GitHub](https://github.com/Carme99/MacCleans.sh) - Source code
