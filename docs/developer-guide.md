# Developer Guide

Interested in contributing to MacCleans? This guide covers everything you need to know.

## Project Structure

```
MacCleans.sh/
├── clean-mac-space.sh      # Main script (entry point)
├── docs/                   # Documentation
├── tests/                  # Test suite
├── installer.sh            # Installation script
└── README.md               # Project readme
```

## Script Architecture

The main script is organized into these sections:

1. **Header** - Constants, usage, and options documentation
2. **Configuration** - Config file loading and parsing
3. **Helper Functions** - Validation and utility functions
4. **Category Functions** - Individual cleanup implementations
5. **Main Logic** - Argument parsing and execution flow

## Adding a New Category

To add a new cleanup category:

### 1. Add Command-Line Options

In the header and argument parsing section:

```bash
# Add to Options section header:
#   --skip-newcategory   Skip NewCategory cleanup

# Add to parse_arguments():
--skip-newcategory)
    SKIP_NEWCATEGORY=true
    shift
    ;;
```

### 2. Add the Variable

Add to the default options section:

```bash
SKIP_NEWCATEGORY=false
```

### 3. Add Configuration Support

In `load_config_file()`:

```bash
SKIP_NEWCATEGORY) SKIP_NEWCATEGORY="$value" ;;
```

In `validate_config()`:

```bash
SKIP_NEWCATEGORY
```

### 4. Add the Cleanup Function

```bash
clean_newcategory() {
    local category="NewCategory"
    local path="$HOME/Library/Caches/com.example.newcategory"
    
    if [ "$SKIP_NEWCATEGORY" = "true" ]; then
        print_skip "$category" "skipped by user"
        return 0
    fi
    
    if [ ! -d "$path" ]; then
        print_skip "$category" "not found"
        return 0
    fi
    
    local size
    size=$(calculate_size "$path")
    
    if [ "$size" -eq 0 ]; then
        print_skip "$category" "empty"
        return 0
    fi
    
    print_found "$category" "$size"
    
    if [ "$DRY_RUN" = "true" ]; then
        return 0
    fi
    
    if [ "$AUTO_YES" = "false" ]; then
        confirm_action "$category" || return 0
    fi
    
    remove_items "$path" "$category"
    return 0
}
```

### 5. Register in Main Logic

Add to the main cleanup flow (around line 3000):

```bash
clean_newcategory
```

### 6. Update Documentation

- Add to [All Categories](all-categories.md)
- Update [Command Reference](command-reference.md)
- Add to [Profiles](profiles.md) if applicable

## Code Style

### Formatting

- 4-space indentation (no tabs)
- Maximum line length: 100 characters
- Blank lines between sections

### Naming

- Functions: `clean_category_name`
- Variables: `UPPER_CASE`
- Constants: `readonly` where possible

### Documentation

- Comments for complex logic
- Update header documentation when adding options
- Document edge cases

## Testing

Run the test suite before submitting changes:

```bash
# Run all tests
npm test

# Run specific test
npm test -- --grep "CategoryName"
```

See [tests/README.md](../tests/README.md) for testing details.

## ShellCheck

MacCleans passes ShellCheck with no errors:

```bash
shellcheck clean-mac-space.sh
```

Before submitting a PR, ensure:

```bash
shellcheck -S warning clean-mac-space.sh
```

No warnings should be introduced.

## Pull Request Guidelines

1. **Branch from `main`**
2. **Keep PRs focused** - one feature or fix per PR
3. **Test thoroughly** - run `--dry-run` and verify output
4. **Update docs** - reflect any changes in documentation
5. **Follow existing patterns** - match the code style

## Reporting Issues

Found a bug? Please report it with:

- macOS version
- MacCleans version (`Mac-Clean --version`)
- Steps to reproduce
- Expected vs actual behavior
- Output with `--verbose` if possible

## Getting Help

| Question | Where to Ask |
|----------|--------------|
| Bug report | [GitHub Issues](https://github.com/Carme99/MacCleans.sh/issues) |
| Feature request | [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions) |
| Contributing help | [GitHub Discussions](https://github.com/Carme99/MacCleans.sh/discussions) |

---

<p align="center">

[Back to Documentation](index.md) · [GitHub Repository](https://github.com/Carme99/MacCleans.sh) · [Issues](https://github.com/Carme99/MacCleans.sh/issues)

</p>
