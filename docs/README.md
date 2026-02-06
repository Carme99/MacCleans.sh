# MacCleans Documentation

[![Docs](https://img.shields.io/badge/Type-Educational%20Guides-blue.svg)]()
[![Community](https://img.shields.io/badge/Community-Driven-green.svg)]()

In-depth guides for understanding macOS maintenance and getting the most out of MacCleans.sh.

## Available Guides

### 📚 [Understanding macOS Cache Files](understanding-macos-caches.md)
Learn what cache files are, why they exist, when it's safe to delete them, and how they affect your Mac's performance.

**Topics covered**:
- Types of macOS caches (system, user, browser, development)
- How caches work and why they grow
- What happens when you delete caches
- Cache vs other file types
- Best practices for cache management
- Common myths debunked

**Read if**: You want to understand what MacCleans actually does under the hood

---

### 🔧 [When to Clean XCode Derived Data](xcode-derived-data-guide.md)
A comprehensive guide to XCode's Derived Data and making smart decisions about when (and when not) to clean it.

**Topics covered**:
- What is Derived Data and why it exists
- The cost of cleaning (rebuild times)
- When you SHOULD clean (XCode broken, disk emergency)
- When you should NOT clean (active development, deadlines)
- Smart cleanup strategies (selective, age-based)
- Real-world examples and case studies

**Read if**: You're an iOS/Mac developer using XCode

---

### 🐳 [Docker Cache Management Best Practices](docker-cache-guide.md)
Master Docker cache management to reclaim massive disk space without breaking your containerized workflows.

**Topics covered**:
- Understanding Docker's disk usage (images, containers, volumes, cache)
- Docker cleanup strategies (safe vs dangerous)
- When to clean Docker caches
- Best practices to minimize waste (multi-stage builds, .dockerignore)
- Monitoring and recovering from Docker disk issues
- Common mistakes to avoid

**Read if**: You use Docker for development or containers

---

### 🤖 [Automating macOS Maintenance](automating-macos-maintenance.md)
Complete guide to automating MacCleans and other maintenance tasks for a hands-off, healthy Mac.

**Topics covered**:
- Why automate maintenance
- Automation methods (Cron vs LaunchD)
- Multi-tier automation strategy (daily/weekly/monthly)
- Custom wrapper scripts with intelligent logic
- Notifications and monitoring (Slack, email, macOS notifications)
- Troubleshooting automation issues

**Read if**: You want set-and-forget automated cleanup

---

## Quick Navigation

**New to MacCleans?** Start here:
1. [Main README](../README.md) - Overview and quick start
2. [Installation Guide](../INSTALL.md) - Get MacCleans set up
3. [Understanding macOS Caches](understanding-macos-caches.md) - Learn what's being cleaned

**Ready to automate?**
1. [Automating macOS Maintenance](automating-macos-maintenance.md) - Set up automated cleanup
2. [Advanced Usage Guide](../ADVANCED.md) - Power user features

**Troubleshooting?**
1. [FAQ](../FAQ.md) - Common questions answered
2. [Troubleshooting Guide](../TROUBLESHOOTING.md) - Fix common issues

**Developer?**
1. [XCode Derived Data Guide](xcode-derived-data-guide.md) - Manage XCode caches
2. [Docker Cache Guide](docker-cache-guide.md) - Docker cleanup best practices
3. [Contributing Guide](../CONTRIBUTING.md) - Add new features

## Contributing to Documentation

Found a typo? Want to add a guide? See [CONTRIBUTING.md](../CONTRIBUTING.md)

Suggestions for new guides:
- npm/Yarn cache deep dive
- Browser cache internals
- Time Machine snapshot management
- System cache categories explained
- Comparison with other cleanup tools

[Open an issue](https://github.com/Carme99/MacCleans.sh/issues) with your idea!

## External Resources

**Related Tools**:
- [Homebrew](https://brew.sh/) - Package manager (has its own cache)
- [Docker](https://www.docker.com/) - Container platform
- [XCode](https://developer.apple.com/xcode/) - Apple's IDE

**macOS Resources**:
- [macOS Storage Management](https://support.apple.com/en-us/HT206996) - Official Apple guide
- [Time Machine](https://support.apple.com/en-us/HT201250) - Backup documentation
- [Disk Utility](https://support.apple.com/guide/disk-utility/) - Apple's disk tool

---

**Back to**: [Main README](../README.md) | [Installation](../INSTALL.md) | [Advanced Guide](../ADVANCED.md)
