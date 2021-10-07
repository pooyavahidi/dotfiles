#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# Setting the prompt similar to default macOS terminal prompt
export PROMPT="%B%F{green}%n@%m%f %1~ %b%# "
