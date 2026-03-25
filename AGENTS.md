# AGENTS.md - MacCleans.sh

> macOS disk cleanup utility. Bash 3.2+, ShellCheck, GitHub Actions CI.

---

## Build / Test / Lint Commands

```bash
# Syntax validation
bash -n clean-mac-space.sh

# ShellCheck linting
shellcheck clean-mac-space.sh

# Test safely with dry-run (ALWAYS do this first!)
sudo ./clean-mac-space.sh --dry-run

# Test with verbose output
bash -x clean-mac-space.sh --dry-run 2>&1 | head -50

# Test JSON output
sudo ./clean-mac-space.sh --dry-run --json | jq '.'

# Test specific scenarios
sudo ./clean-mac-space.sh --dry-run --interactive
sudo ./clean-mac-space.sh --dry-run --profile conservative
```

---

## Code Style Guidelines

### Bash Best Practices

```bash
# Use set flags for safety
set -euo pipefail

# Quote ALL variables
echo "$variable"              # Good
echo $variable               # Bad

# Use [[ ]] for conditionals
if [[ "$var" == "value" ]]; then  # Good

# Use local for function variables
cleanup_cache() {
    local cache_path="${USER_HOME}/Library/Caches"
    local initial_size=0
}

# Check command existence before using
if command -v docker &> /dev/null; then
    docker system prune
fi
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Constants | UPPERCASE | `MAX_SIZE=1000` |
| Globals | UPPER_SNAKE | `TOTAL_FREED=0` |
| Locals | snake_case | `local category_name="Cache"` |
| Functions | snake_case | `cleanup_category()` |
| Skip flags | `SKIP_CATEGORY` | `SKIP_CACHE=false` |

### Error Handling

```bash
# Always suppress expected errors
rm -rf /path/to/cache 2>/dev/null || true

# Log unexpected errors
if ! critical_operation; then
    log_error "Critical operation failed"
    exit 1
fi

# Validate inputs
if [[ -z "${USER_HOME}" ]]; then
    log_error "Cannot determine user home directory"
    exit 1
fi
```

---

## Project Structure

```
MacCleans.sh/
├── clean-mac-space.sh     # Main script
├── installer.sh           # Installation script
├── completions/           # Shell completions
│   └── maccleans.bash
├── docs/                  # Documentation
│   ├── faq.md
│   └── advanced.md
├── .github/               # GitHub Actions CI
│   └── workflows/
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

---

## Adding New Cleanup Categories

1. Create cleanup function following existing pattern
2. Add skip flag variable (e.g., `SKIP_MY_CATEGORY=false`)
3. Add command-line argument (`--skip-my-category`)
4. Update help text in `show_help()`
5. Add to interactive mode categories array
6. Call function in `main()`
7. Update README.md and CHANGELOG.md

---

## Commit & Branch Style

- **Commits:** `type: description` (feat, fix, docs, refactor, chore)
- **Branches:** `feature/name`, `fix/description`, `docs/changes`

---

## Key Notes

- ALWAYS test with `--dry-run` before actual cleanup
- Never hardcode paths — use variables
- Use `2>/dev/null || true` for expected errors
- Check ShellCheck before committing
- Test on macOS 10.15+ (Catalina or later)