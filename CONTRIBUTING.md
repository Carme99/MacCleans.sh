# Contributing to MacCleans.sh

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Carme99/MacCleans.sh/pulls)
[![Code Style](https://img.shields.io/badge/code%20style-shellcheck-blue.svg)](https://www.shellcheck.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Thank you for considering contributing to MacCleans.sh! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Testing Your Changes](#testing-your-changes)
- [Code Style Guidelines](#code-style-guidelines)
- [Adding New Cleanup Categories](#adding-new-cleanup-categories)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow. Please be respectful, inclusive, and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **macOS Version**: Output of `sw_vers`
- **Script Version**: Output of `./clean-mac-space.sh --version`
- **Command Used**: The exact command you ran
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Error Messages**: Full error output (use `--no-color` for cleaner logs)
- **Disk Space**: Output of `df -h`

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. Include:

- **Clear Use Case**: Why this enhancement would be useful
- **Proposed Solution**: How you envision it working
- **Alternatives Considered**: Other approaches you've thought about
- **Space Recovery Potential**: Estimated disk space this could free

### Pull Requests

We actively welcome pull requests for:

- Bug fixes
- New cleanup categories
- Documentation improvements
- Performance optimizations
- Code quality improvements
- New features (discuss in an issue first)

## Development Setup

### Prerequisites

- macOS 10.15+ (Catalina or later)
- Bash 3.2+ (comes with macOS)
- Git
- ShellCheck (for linting)

### Installing ShellCheck

```bash
# Using Homebrew
brew install shellcheck

# Or download from https://www.shellcheck.net/
```

### Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/MacCleans.sh.git
cd MacCleans.sh

# Add upstream remote
git remote add upstream https://github.com/Carme99/MacCleans.sh.git
```

### Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-description

# Or for documentation
git checkout -b docs/documentation-update
```

## Testing Your Changes

**CRITICAL**: Test safely to avoid accidental data loss!

### 1. Test with Dry-Run First

**ALWAYS** test with `--dry-run` before making actual changes:

```bash
# Test your changes without deleting anything
sudo ./clean-mac-space.sh --dry-run
```

### 2. Test on a Non-Production System

If possible, test on:
- A secondary Mac
- A virtual machine
- A test user account

### 3. Test Individual Categories

Test your specific changes in isolation:

```bash
# If you added a new category, skip everything else
sudo ./clean-mac-space.sh --dry-run --skip-xcode --skip-browsers --skip-npm # etc
```

### 4. Test Different Scenarios

Test with various flag combinations:

```bash
# Test all modes
sudo ./clean-mac-space.sh --dry-run
sudo ./clean-mac-space.sh --dry-run --yes
sudo ./clean-mac-space.sh --dry-run --quiet
sudo ./clean-mac-space.sh --dry-run --interactive
sudo ./clean-mac-space.sh --dry-run --profile conservative
sudo ./clean-mac-space.sh --dry-run --threshold 90
sudo ./clean-mac-space.sh --dry-run --no-color

# Test your specific category's skip flag
sudo ./clean-mac-space.sh --dry-run --skip-your-category
```

### 5. Test Edge Cases

```bash
# Test when directories don't exist
# Test with insufficient permissions
# Test with disk at various capacity levels
# Test with active backups running
```

### 6. Verify ShellCheck Compliance

```bash
# Run ShellCheck on the script
shellcheck clean-mac-space.sh

# Should produce no errors or warnings
```

### 7. Test Configuration Files

```bash
# Test with config file
cp maccleans.conf.example ~/.maccleans.conf
# Edit config to set your new options
sudo ./clean-mac-space.sh --dry-run
```

### 8. Manual Testing Checklist

- [ ] Script runs without errors in dry-run mode
- [ ] New category shows in summary report
- [ ] Space calculations are accurate
- [ ] Skip flag works correctly
- [ ] Interactive mode includes new category
- [ ] Help text is updated
- [ ] No ShellCheck warnings
- [ ] Config file options work
- [ ] Error handling works (test with invalid paths)
- [ ] Cleanup actually works (run without --dry-run on test system)

## Code Style Guidelines

### Bash Best Practices

We follow strict bash scripting standards enforced by ShellCheck:

```bash
# Use set flags for safety
set -euo pipefail

# Quote all variables
echo "$variable"              # Good
echo $variable               # Bad

# Use [[ ]] for conditionals
if [[ "$var" == "value" ]]; then  # Good
if [ "$var" == "value" ]; then    # Acceptable
if [ $var == "value" ]; then      # Bad (unquoted)

# Use local for function variables
function_name() {
    local var="value"        # Good
    var="value"              # Bad
}

# Check command existence before using
if command -v docker &> /dev/null; then
    docker system prune
fi

# Use arrays for lists
local -a files=("file1" "file2" "file3")

# Proper error handling
if ! some_command; then
    log_error "Command failed"
    return 1
fi
```

### Naming Conventions

```bash
# Constants (readonly)
readonly MAX_SIZE=1000

# Global variables
TOTAL_FREED=0

# Local variables (in functions)
local category_name="Cache"

# Functions - use snake_case
cleanup_category() {
    # Function body
}

# Skip flags - use consistent naming
SKIP_CATEGORY=false
```

### Code Organization

1. **File Structure**:
   - Script metadata (shebang, set flags, version)
   - Constants and configuration
   - Utility functions (logging, formatting)
   - Cleanup functions (one per category)
   - Main execution functions
   - Argument parsing
   - Main execution

2. **Function Structure**:
   ```bash
   cleanup_category_name() {
       # Skip if disabled
       if [[ "${SKIP_CATEGORY}" == "true" ]]; then
           log_skip "Category Name"
           return 0
       fi

       # Log start
       log_info "Cleaning Category Name..."

       # Get initial size
       local initial_size=0
       if [[ -d "/path/to/category" ]]; then
           initial_size=$(du -sk "/path/to/category" 2>/dev/null | awk '{print $1}')
       fi

       # Dry run check
       if [[ "${DRY_RUN}" == "true" ]]; then
           log_dry_run "Would delete: /path/to/category"
           return 0
       fi

       # Perform cleanup
       if [[ -d "/path/to/category" ]]; then
           rm -rf "/path/to/category" 2>/dev/null || true
       fi

       # Calculate and report freed space
       local freed=$((initial_size))
       TOTAL_FREED=$((TOTAL_FREED + freed))
       log_success "Cleaned Category Name: $(format_size $freed)"
   }
   ```

### Comments

```bash
# Use comments to explain WHY, not WHAT
# Good: Explain reasoning
# We skip if Xcode is open to avoid breaking active builds
if pgrep -x "Xcode" > /dev/null; then
    return 0
fi

# Bad: Stating the obvious
# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
```

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

## Adding New Cleanup Categories

Follow these steps to add a new cleanup category:

### 1. Create the Cleanup Function

Add your function to the cleanup section of the script:

```bash
cleanup_my_new_category() {
    # Check skip flag
    if [[ "${SKIP_MY_CATEGORY}" == "true" ]]; then
        log_skip "My New Category"
        SKIPPED_CATEGORIES+=("My New Category")
        return 0
    fi

    log_info "Cleaning My New Category..."

    # Calculate initial size
    local category_path="${USER_HOME}/Library/Caches/MyApp"
    local initial_size=0

    if [[ -d "${category_path}" ]]; then
        initial_size=$(du -sk "${category_path}" 2>/dev/null | awk '{print $1}')
    fi

    # Handle dry-run
    if [[ "${DRY_RUN}" == "true" ]]; then
        if [[ -d "${category_path}" ]]; then
            log_dry_run "Would delete: ${category_path} ($(format_size ${initial_size}))"
        else
            log_dry_run "Would delete: ${category_path} (not found)"
        fi
        return 0
    fi

    # Perform cleanup
    if [[ -d "${category_path}" ]]; then
        rm -rf "${category_path}" 2>/dev/null || true
        log_success "Cleaned My New Category: $(format_size ${initial_size})"
        TOTAL_FREED=$((TOTAL_FREED + initial_size))
        PROCESSED_CATEGORIES+=("My New Category")
    else
        log_info "My New Category cache not found, skipping"
    fi
}
```

### 2. Add Skip Flag Variable

Add to the default variables section:

```bash
SKIP_MY_CATEGORY=false
```

### 3. Add Command-Line Argument

Add to the argument parsing section:

```bash
--skip-my-category)
    SKIP_MY_CATEGORY=true
    shift
    ;;
```

### 4. Add to Help Text

Update the `show_help()` function:

```bash
  --skip-my-category       Skip My New Category cleanup
```

### 5. Add to Interactive Mode

Add to the `interactive_select_categories()` function in the categories array:

```bash
local -a categories=(
    # ... existing categories ...
    "cleanup_my_new_category:My New Category:SKIP_MY_CATEGORY"
)
```

### 6. Add to Configuration Profile (if applicable)

If your category fits into existing profiles, add to the profile section:

```bash
conservative)
    SKIP_MY_CATEGORY=true  # Add if it's a development/risky category
    ;;
```

### 7. Call in Main Execution

Add to the `main()` function:

```bash
cleanup_my_new_category
```

### 8. Update Documentation

- Add to README.md "What Gets Cleaned" section
- Add to CHANGELOG.md
- Add space recovery estimate
- Add FAQ entry if needed

### 9. Test Thoroughly

```bash
# Test all scenarios
sudo ./clean-mac-space.sh --dry-run
sudo ./clean-mac-space.sh --dry-run --skip-my-category
sudo ./clean-mac-space.sh --dry-run --interactive
```

## Submitting Changes

### Before Submitting

- [ ] Run ShellCheck: `shellcheck clean-mac-space.sh`
- [ ] Test with `--dry-run`
- [ ] Test with `--interactive`
- [ ] Test skip flags
- [ ] Update CHANGELOG.md
- [ ] Update README.md if needed
- [ ] Add comments explaining complex logic
- [ ] Verify no hardcoded paths (use variables)

### Commit Messages

Follow conventional commit format:

```bash
# Format
<type>(<scope>): <subject>

# Types
feat:     New feature
fix:      Bug fix
docs:     Documentation only
style:    Code style (formatting, no logic change)
refactor: Code refactoring
test:     Adding tests
chore:    Maintenance tasks

# Examples
feat(cleanup): add Gradle cache cleanup category
fix(docker): handle missing docker command gracefully
docs(readme): update installation instructions
refactor(logging): improve error message formatting
```

### Pull Request Process

1. **Update your branch**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push your changes**:
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request** on GitHub with:
   - Clear title describing the change
   - Description explaining what and why
   - Reference any related issues
   - Include testing steps
   - Add before/after examples if applicable

4. **PR Template**:
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Code refactoring

   ## Testing
   - [ ] Tested with --dry-run
   - [ ] Tested skip flags
   - [ ] Tested interactive mode
   - [ ] ShellCheck passes

   ## Screenshots (if applicable)

   ## Related Issues
   Closes #123
   ```

5. **Respond to feedback**: Address reviewer comments promptly

6. **Squash commits** (if requested):
   ```bash
   git rebase -i upstream/main
   ```

## Release Process

For maintainers releasing new versions:

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (x.X.0): New features (backward compatible)
- **PATCH** (x.x.X): Bug fixes

### Release Checklist

1. Update version number in script
2. Update CHANGELOG.md
3. Update README.md badges
4. Test on clean macOS installation
5. Create git tag: `git tag -a v3.1.0 -m "Version 3.1.0"`
6. Push tag: `git push origin v3.1.0`
7. Create GitHub release with changelog
8. Update documentation if needed

## Questions?

- Open an issue for questions
- Check existing issues and discussions
- Read the [FAQ](FAQ.md)
- Review [Advanced Usage Guide](ADVANCED.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to MacCleans.sh!** 🎉
