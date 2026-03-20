#!/bin/bash
# Bash completion for mac-cleans
# Install: cp mac-cleans.bash /usr/local/etc/bash_completion.d/

_mac_cleans() {
    local cur prev words cword
    _init_completion || return

    local options="--dry-run --force --yes --interactive --json --version --help"
    local categories="--skip-xcode --skip-homebrew --skip-docker --skip-npm --skip-pip"
    categories+=" --skip-chrome --skip-firefox --skip-edge --skip-spotify --skip-mail"
    categories+=" --skip-icloud --skip-trash --skip-gradle --skip-bun --skip-pnpm"
    categories+=" --skip-photos --skip-quicklook --skip-diagnostics"

    if [[ "$cur" == --* ]]; then
        COMPREPLY=($(compgen -W "$options $categories" -- "$cur"))
    fi
}

complete -F _mac_cleans mac-cleans
complete -F _mac_cleans Mac-Clean
