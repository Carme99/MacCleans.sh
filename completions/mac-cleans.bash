#!/bin/bash
# Bash completion for mac-cleans
# Install: cp mac-cleans.bash /usr/local/etc/bash_completion.d/

_mac_cleans() {
    local cur IFS=$' \t\n'
    cur="${COMP_WORDS[COMP_CWORD]}"

    local -a options=(
        --dry-run --force --yes --interactive --json --version --help
        --skip-snapshots --skip-homebrew --skip-spotify --skip-claude
        --skip-xcode --skip-browsers --skip-npm --skip-pip --skip-trash
        --skip-dsstore --skip-docker --skip-simulator --skip-mail
        --skip-siri-tts --skip-icloud-mail --skip-photos-library
        --skip-icloud-drive --skip-quicklook --skip-diagnostics
        --skip-ios-backups --skip-ios-updates --skip-cocoapods
        --skip-gradle --skip-go --skip-bun --skip-pnpm
        --skip-system-tmp --clean-system-tmp
    )

    # NOTE: intentionally NOT using `mapfile` (a bash 4+ builtin) so the
    # completion loads on macOS's bundled bash 3.2.57. We use a simple
    # for-loop prefix match instead.
    local option
    COMPREPLY=()
    for option in "${options[@]}"; do
        if [[ "$option" == "$cur"* ]]; then
            COMPREPLY+=("$option")
        fi
    done
}

complete -F _mac_cleans mac-cleans
complete -F _mac_cleans Mac-Clean
