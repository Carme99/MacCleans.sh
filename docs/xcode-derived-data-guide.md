# When to Clean XCode Derived Data

[![XCode](https://img.shields.io/badge/XCode-Developer%20Guide-blue.svg)]()
[![iOS](https://img.shields.io/badge/iOS-Development-orange.svg)]()

A comprehensive guide to understanding XCode's Derived Data and making smart decisions about when to clean it.

## What is XCode Derived Data?

**Derived Data** is XCode's build cache containing all the compiled outputs and intermediate files from your projects.

**Location**: `~/Library/Developer/Xcode/DerivedData/`

**What it contains**:
- Compiled object files (.o)
- Built frameworks and libraries
- Index data for code completion
- Debug symbols (dSYM files)
- Build logs
- Module caches
- Precompiled headers

**Size**: 5GB - 50GB+ depending on:
- Number of projects
- Project size
- How long since last cleanup
- Number of architectures built (arm64, x86_64, etc.)

## Why XCode Creates Derived Data

### The Build Process

When you build an XCode project:

```
1. Read source code (.swift, .m, .h files)
   ↓
2. Compile to object files (.o) ← Saved in Derived Data
   ↓
3. Link object files into binary ← Saved in Derived Data
   ↓
4. Create app bundle (.app) ← Final product
```

**Derived Data caches steps 2-3** so XCode only recompiles files that changed, not the entire project.

### Incremental Builds

**Without Derived Data**:
- Change one line of code
- Recompile ALL files (5-30 minutes)
- Very slow development cycle

**With Derived Data**:
- Change one line of code
- Recompile only that file (5-30 seconds)
- Fast iterative development

**This is why Derived Data exists!**

## The Cost of Derived Data

### Disk Space Impact

Typical sizes per project:
- **Small project** (< 100 files): 500MB - 2GB
- **Medium project** (< 1000 files): 2GB - 10GB
- **Large project** (> 1000 files): 10GB - 30GB
- **Huge project** (with dependencies): 30GB - 50GB+

**Multiple projects compound this**:
- 3 medium projects = 6GB - 30GB
- 5 small projects + 2 large = 15GB - 50GB

### What Happens When It's Gone

**Immediate impact**:
- ✅ Disk space freed (5-50GB)
- ❌ Next build is SLOW

**Next build after cleanup**:
- Clean build (compiles everything from scratch)
- Time depends on project size:
  - Small: 2-5 minutes
  - Medium: 5-15 minutes
  - Large: 15-30 minutes
  - Huge: 30+ minutes

**Subsequent builds**: Back to normal (incremental)

## When You SHOULD Clean Derived Data

### 1. XCode is Acting Weird 🐛

**Symptoms**:
- Code completion not working
- Build succeeds but app crashes
- "Module not found" errors (but it exists)
- Phantom compile errors
- Stale autocomplete suggestions
- Debugger showing wrong values

**Why it helps**:
Corrupted index or stale build artifacts can cause bizarre behavior. Clean slate fixes it.

**How to clean**:
```bash
# MacCleans
sudo ./clean-mac-space.sh --profile developer --skip-all-but-xcode

# Or manually
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 2. Disk Space Emergency 🚨

**Scenario**: Disk is >95% full and you need space NOW

**Why it makes sense**:
- XCode Derived Data is often the largest cache
- Can free 10-50GB instantly
- Everything can be rebuilt

**Trade-off accepted**: Slow next build vs unusable disk

### 3. Haven't Used XCode in Months 📅

**Scenario**: Last XCode project was 3+ months ago

**Why clean**:
- Derived Data is outdated anyway
- Would do clean build on next open
- No active development impacted

**Safe bet**: You won't feel the rebuild cost

### 4. Switching XCode Versions 🔄

**Scenario**: Upgrading from XCode 14 → XCode 15

**Why clean**:
- Derived Data format may have changed
- Avoid compatibility issues
- Force rebuild with new compiler

**Best practice**: Clean between major XCode updates

### 5. Before Major Refactoring 🏗️

**Scenario**: About to rename modules, restructure folders, change dependencies

**Why clean**:
- Old references in index cause confusion
- Fresh index after refactor
- Avoid stale import errors

**Timing**: Clean AFTER refactor, before next build

### 6. Mysterious Build Issues 🤔

**Symptoms**:
- "Linker error" but all files present
- Works on coworker's machine
- Clean build in XCode doesn't help
- Stale framework references

**Why it helps**: Nuclear option - destroys all build state

**Last resort**: After trying "Clean Build Folder" in XCode

### 7. CI/CD Pipeline Cleanup 🤖

**Scenario**: Build server running out of space

**Why clean**:
- Build servers accumulate Derived Data from many builds
- Fresh build each time anyway (not iterative)
- Automation handles rebuild time

**Best practice**: Clean Derived Data after each CI build

## When You Should NOT Clean Derived Data

### 1. Active Development 👨‍💻

**Scenario**: Working on a project right now

**Why not**:
- You're benefiting from incremental builds
- Next build will be painfully slow
- Kills productivity

**Exception**: Unless XCode is broken (see "should clean" #1)

### 2. Right Before a Deadline ⏰

**Scenario**: App demo in 2 hours, need quick build

**Why not**:
- 30-minute clean build vs 30-second incremental
- Risk missing deadline
- Not worth the disk space

**Do instead**: Delete other caches (browsers, npm, etc.)

### 3. About to Archive for Release 📦

**Scenario**: Creating production build for App Store

**Why not**:
- Release builds take longer than debug builds
- Clean build adds extra time
- Already time-consuming process

**Do instead**: Clean AFTER release is submitted

### 4. Multiple Projects Active 🗂️

**Scenario**: Switching between 3 projects throughout the day

**Why not**:
- Each project benefits from incremental builds
- Cleaning nukes all of them
- Slows down all your projects

**Do instead**: Clean oldest/unused projects only

### 5. On a Slow Machine 🐌

**Scenario**: Older Mac, slow CPU

**Why not**:
- Clean builds are even slower on old hardware
- Can take 45-60 minutes
- Incremental builds are your friend

**Do instead**: Upgrade hardware before cleaning aggressively

### 6. Low Disk Space, But Not Critical ⚠️

**Scenario**: Disk at 75%, comfortable for now

**Why not**:
- Not urgent enough to justify rebuild time
- Other caches can free space (browsers, Docker)
- XCode cache is the nuclear option

**Do instead**: Clean other categories first

## Smart Cleanup Strategies

### Strategy 1: Selective Project Cleanup

Clean specific projects, not everything:

```bash
# List all Derived Data folders
ls ~/Library/Developer/Xcode/DerivedData/

# Output example:
# ProjectA-abc123xyz/
# ProjectB-def456uvw/
# ProjectC-ghi789rst/

# Delete only old project
rm -rf ~/Library/Developer/Xcode/DerivedData/ProjectB-def456uvw/
```

**When to use**: You know which project is huge or unused

### Strategy 2: Age-Based Cleanup

Delete Derived Data older than 30 days:

```bash
find ~/Library/Developer/Xcode/DerivedData -type d -maxdepth 1 -mtime +30 -exec rm -rf {} \;
```

**When to use**: Regular maintenance without affecting active projects

### Strategy 3: Size-Based Cleanup

Delete largest Derived Data folders:

```bash
# Find largest folders
du -sh ~/Library/Developer/Xcode/DerivedData/* | sort -rh | head -5

# Manually delete the biggest ones
```

**When to use**: Target space hogs, keep small caches

### Strategy 4: Use XCode's Built-in Cleanup

XCode → Preferences → Locations → Derived Data → Arrow icon → Delete

**Pros**:
- Official method
- GUI if you prefer
- Safe

**Cons**:
- Deletes everything (not selective)
- Still slow rebuild

### Strategy 5: Automated Threshold Cleanup

Use MacCleans with threshold:

```bash
# Only clean if disk >85% full
sudo ./clean-mac-space.sh --threshold 85 --skip-xcode

# If REALLY full (>95%), include XCode
sudo ./clean-mac-space.sh --threshold 95
```

**When to use**: Automated cleanup that's smart about urgency

## Derived Data vs Other XCode Caches

XCode creates multiple caches:

| Cache Type | Location | Size | Impact if Deleted |
|------------|----------|------|-------------------|
| **Derived Data** | `~/Library/Developer/Xcode/DerivedData/` | 5-50GB | ⚠️ Slow next build |
| **Archives** | `~/Library/Developer/Xcode/Archives/` | 1-10GB | ❌ Can't resubmit old builds |
| **Device Support** | `~/Library/Developer/Xcode/iOS DeviceSupport/` | 5-20GB | ⚠️ Re-downloads on next device connect |
| **Simulator Data** | `~/Library/Developer/CoreSimulator/` | 1-10GB | ✅ Simulators recreate |
| **Module Cache** | `~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/` | 500MB-2GB | ✅ Rebuilds quickly |

**Safest to delete**: Simulator Data, Module Cache
**Least safe**: Archives (can't recover)
**Middle ground**: Derived Data (can rebuild, but slow)

## Understanding the Rebuild Process

### What Happens During a Clean Build

```
1. Parse project files
   ↓
2. Resolve dependencies
   ↓
3. Download Swift packages (if needed)
   ↓
4. Compile each .swift/.m file → .o files
   ↓ (This is the slow part!)
5. Link all .o files into frameworks
   ↓
6. Link frameworks into final app
   ↓
7. Code sign
   ↓
8. Create .app bundle
```

**Steps 4-5 are why clean builds are slow** - compiling every file

### Incremental Build (Normal)

```
1. Detect changed files (git diff, timestamps)
   ↓
2. Recompile ONLY changed files
   ↓ (Fast! Maybe 1-10 files)
3. Re-link (fast with modern linkers)
   ↓
4. Done!
```

**This is why Derived Data matters** - keeps step 2 minimal

## Real-World Examples

### Example 1: The Space Emergency

**Situation**: Disk 98% full, can't install macOS update

**Action**: Clean everything including XCode
```bash
sudo ./clean-mac-space.sh --profile aggressive
```

**Result**: Freed 45GB, install succeeded

**Trade-off**: Next 3 builds took 15 minutes each instead of 30 seconds

**Worth it?** ✅ Yes - had no choice

### Example 2: The Phantom Bug

**Situation**: App crashes on launch, code looks correct, colleagues' builds work

**Action**: Clean Derived Data only
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/MyApp-*/
```

**Result**: Next build took 12 minutes, but app worked!

**Worth it?** ✅ Yes - corrupted build artifact was the issue

### Example 3: The Deadline Disaster

**Situation**: App demo in 1 hour, disk at 85%

**Action**: Cleaned XCode Derived Data

**Result**: Build took 25 minutes, almost missed demo

**Worth it?** ❌ No - should have cleaned other caches first

**Lesson**: XCode cleanup is the last resort, not first option

### Example 4: The Monthly Maintenance

**Situation**: Regular cleanup, no active XCode work this week

**Action**: Clean Derived Data as part of monthly maintenance

**Result**: Freed 23GB, didn't notice rebuild time (not actively coding)

**Worth it?** ✅ Yes - cleaned during downtime

## Best Practices Summary

### Do's ✅

- ✅ Clean when XCode is misbehaving
- ✅ Clean during downtime (weekends, between projects)
- ✅ Clean selectively (old projects only)
- ✅ Clean before major refactoring
- ✅ Use dry-run to preview size first
- ✅ Clean after switching XCode versions

### Don'ts ❌

- ❌ Clean during active development
- ❌ Clean right before deadlines
- ❌ Clean multiple times per week
- ❌ Clean without checking disk space first
- ❌ Clean if other caches can free enough space
- ❌ Clean and expect fast builds

### The Golden Rule

> **Clean XCode Derived Data when the pain of slow builds < the pain of full disk or broken XCode**

## Alternatives to Cleaning

### 1. Upgrade Storage

- Buy external SSD
- Upgrade internal SSD
- Use iCloud to offload files

**Pro**: Never clean again
**Con**: Costs money

### 2. Clean Other Caches First

```bash
# Clean everything EXCEPT XCode
sudo ./clean-mac-space.sh --skip-xcode
```

**Pro**: No rebuild penalty
**Con**: Less space freed

### 3. Delete Old Simulators

```bash
xcrun simctl delete unavailable
```

**Pro**: Frees 1-5GB, keeps Derived Data
**Con**: Limited space recovery

### 4. Archive Old Projects

Move unused projects to external drive:

```bash
# Tar up old project
tar -czf OldProject.tar.gz ~/Projects/OldProject/

# Move to external drive
mv OldProject.tar.gz /Volumes/ExternalDrive/

# Delete from Mac
rm -rf ~/Projects/OldProject/
```

**Pro**: Keeps Derived Data for active projects
**Con**: Manual process

## Monitoring Derived Data Growth

Track growth over time:

```bash
# Check total size
du -sh ~/Library/Developer/Xcode/DerivedData/

# Check per-project
du -sh ~/Library/Developer/Xcode/DerivedData/*/ | sort -rh

# Track in a script
echo "$(date): $(du -sh ~/Library/Developer/Xcode/DerivedData/ | awk '{print $1}')" >> ~/derived-data-log.txt
```

**Red flags**:
- Growing >1GB per day (huge project or leak)
- >50GB total (time for cleanup)
- Individual project >30GB (investigate why)

## FAQ

**Q: How often should I clean Derived Data?**
A: When needed (XCode broken, disk full), not on a schedule. Unlike other caches, this one helps you.

**Q: Will I lose my app?**
A: No! Derived Data is build artifacts, not source code. Your code is safe.

**Q: Can I move Derived Data to external drive?**
A: Technically yes (symlink), but builds will be much slower over USB.

**Q: What's the difference between "Clean Build Folder" and deleting Derived Data?**
A: "Clean Build Folder" clears current project's build. Deleting Derived Data clears ALL projects.

**Q: Does Derived Data contain personal data?**
A: Only build logs (which may have file paths). No user data.

**Q: Is 50GB of Derived Data normal?**
A: For active developers with multiple large projects, yes.

## Summary

**When to Clean Derived Data**:
- 🐛 XCode is broken
- 🚨 Disk emergency (>95% full)
- 📅 Haven't coded in months
- 🔄 Switching XCode versions

**When NOT to Clean**:
- 👨‍💻 Active development
- ⏰ Before deadline
- 📦 About to release
- 🐌 On slow machine + not urgent

**Smart Strategy**: Clean selectively, during downtime, as last resort for space

---

**Related Reading**:
- [Understanding macOS Caches](understanding-macos-caches.md)
- [Docker Cache Management](docker-cache-guide.md)
- [Back to Main README](../README.md)
