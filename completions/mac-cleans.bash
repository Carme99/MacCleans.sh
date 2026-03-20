#!/bin/bash
# Bash completion for mac-cleans
# Install: cp mac-cleans.bash /usr/local/etc/bash_completion.d/

_mac_cleans() {
    local cur IFS=$' \t\n'
    cur="${COMP_WORDS[COMP_CWORD]}"

    local -a options=(
        --dry-run --force --yes --interactive --json --version --help
        --skip-xcode --skip-homebrew --skip-docker --skip-npm --skip-pip
        --skip-chrome --skip-firefox --skip-edge --skip-spotify --skip-mail
        --skip-icloud --skip-trash --skip-gradle --skip-bun --skip-pnpm
        --skip-photos --skip-quicklook --skip-diagnostics
    )

    mapfile -t COMPREPLY < <(compgen -W "${options[*]}" -- "$cur")
}

complete -F _mac_cleans mac-cleans
complete -F _mac_cleans Mac-Clean
