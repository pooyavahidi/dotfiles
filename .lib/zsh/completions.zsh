#!/bin/sh

# Quick Paths Completion
__quick_path_completion() {
    local __keys

    if [[ -n "${QUICK_PATHS}" ]]; then
        __keys=("${(@k)QUICK_PATHS}")
        compadd "$@" -- ${__keys}
    fi
}

# Define completion for the following commands
compdef __quick_path_completion qp
compdef __quick_path_completion j
compdef __quick_path_completion c
compdef __quick_path_completion jc


# If kubectl exists, add its completion
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
