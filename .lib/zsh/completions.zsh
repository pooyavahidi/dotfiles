#!/bin/sh

# If kubectl exists, add its completion
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
