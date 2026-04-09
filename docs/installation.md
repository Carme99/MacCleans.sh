# Installation

This guide covers different methods to install and set up MacCleans on your macOS system.

## Prerequisites

- macOS 10.15 (Catalina) or later
- Admin privileges (sudo access)
- Terminal application

## Installation Methods

### Homebrew (Recommended)

The easiest way to install and update MacCleans.

```bash
# Add the tap
brew tap carme99/tap

# Install
brew install mac-cleans

# Update
brew upgrade mac-cleans
```

### Curl Installer

Download and run the installer script:

```bash
curl -fsSL https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/installer.sh | bash
```

The installer will:
1. Download the latest version
2. Make it executable
3. Install to `/usr/local/bin/Mac-Clean`
4. Optionally install shell completions

### Manual Installation

Download the script directly:

```bash
# Download to /usr/local/bin
sudo curl -o /usr/local/bin/Mac-Clean \
  https://raw.githubusercontent.com/Carme99/MacCleans.sh/main/clean-mac-space.sh

# Make executable
sudo chmod +x /usr/local/bin/Mac-Clean
```

### Git Clone

If you want the full repository:

```bash
# Clone the repository
git clone https://github.com/Carme99/MacCleans.sh.git

# Change to directory
cd MacCleans.sh

# Make executable
chmod +x clean-mac-space.sh

# Run directly (with ./ prefix)
sudo ./clean-mac-space.sh --dry-run
```

Or create a symlink:

```bash
# Create symlink to /usr/local/bin
sudo ln -s ~/MacCleans.sh/clean-mac-space.sh /usr/local/bin/Mac-Clean

# Now you can run from anywhere
sudo Mac-Clean --dry-run
```

## Post-Installation Verification

After installing, verify everything works:

```bash
# Check version
Mac-Clean --version

# Run dry-run to verify installation
sudo Mac-Clean --dry-run

# Check help
Mac-Clean --help
```

## Shell Completions

Shell completions provide tab completion for commands and flags.

### Homebrew Installation

Completions are installed automatically with Homebrew.

### Manual Installation

For **Bash**:

```bash
# Copy completion file
sudo cp completions/mac-cleans.bash /etc/bash_completion.d/

# Reload shell
source ~/.bashrc
```

For **Zsh**:

```bash
# Add to .zshrc
echo 'fpath=(~/MacCleans.sh/completions $fpath)' >> ~/.zshrc
autoload -Uz compinit && compinit
```

For **Fish**:

```bash
# Copy fish completion
mkdir -p ~/.config/fish/completions
cp completions/mac-cleans.fish ~/.config/fish/completions/
```

## Configuration

MacCleans supports configuration files for persistent settings.

See [Configuration](configuration.md) for full details.

Quick setup:

```bash
# Create config directory
mkdir -p ~/.config/mac-cleans

# Copy example config
cp maccleans.conf.example ~/.config/mac-cleans/config

# Edit to your preferences
nano ~/.config/mac-cleans/config
```

## Uninstall

### Homebrew

```bash
brew uninstall mac-cleans
brew untap carme99/tap
```

### Manual/Curl Installation

```bash
# Remove the script
sudo rm /usr/local/bin/Mac-Clean

# Remove completions
sudo rm /etc/bash_completion.d/mac-cleans.bash

# Remove config (optional)
rm -rf ~/.config/mac-cleans
rm ~/.maccleans.conf
```

## Troubleshooting

### "command not found"

If you get "command not found" after installation:

1. Check if `/usr/local/bin` is in your PATH:
   ```bash
   echo $PATH | grep /usr/local/bin
   ```

2. If not found, add to your shell config:
   ```bash
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. Or use the full path:
   ```bash
   sudo /usr/local/bin/Mac-Clean --dry-run
   ```

### Permission Denied

Make sure the script is executable:

```bash
sudo chmod +x /usr/local/bin/Mac-Clean
```

And that you're using `sudo`:

```bash
sudo Mac-Clean --dry-run
```

### macOS Blocking the Script

If macOS says the script can't be opened:

1. Go to System Settings → Privacy & Security
2. Find the message about Mac-Clean being blocked
3. Click "Open Anyway"

## Next Steps

| Guide | Description |
|-------|-------------|
| [Getting Started](getting-started.md) | Run your first cleanup |
| [Configuration](configuration.md) | Set up persistent config |
| [Automation](automation.md) | Set up scheduled cleanup |

---

<p align="center">

[Back to Documentation](index.md) · [Getting Started](getting-started.md)

</p>
