#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# Set the prompt variables.
# Git Prompt Info
SHELL_PROMPT_GIT_BRANCH_PREFIX="%B%F{blue}(%f%F{red}"
SHELL_PROMPT_GIT_BRANCH_SUFFIX="%f%F{blue})%f%b "
SHELL_PROMPT_GIT_DIRTY="%F{yellow}✗%f"
SHELL_PROMPT_GIT_STATUS_PREFIX=""
SHELL_PROMPT_GIT_STATUS_SUFFIX=" "
SHELL_PROMPT_GIT_AHEAD="%F{yellow}⇡%f"
SHELL_PROMPT_GIT_BEHIND="%F{yellow}⇣%f"

SHELL_PROMPT_USER_HOST="%F{green}%n@%m%f"

# Initial arrow. if the last command was successful, shows green, if error, red.
SHELL_PROMPT_INITIAL_ARROW="%B%(?:%F{green}➜%f:%F{red}➜%f)%b"

# Current Directory info, to show the full path relative to HOME, replace %c with %~
SHELL_PROMPT_DIR_INFO="%B%F{cyan}%c%f%b"


# Set the PROMPT
# To set the prompt to the MacOS default use the following.
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

PROMPT=$SHELL_PROMPT_INITIAL_ARROW

# Show user@hostname if connected via SSH or it's inside a container.
if [[ "${SSH_TTY}" ]] || [[ "${SSH_CONNECTION}" ]] || _is_in_container; then
    PROMPT+="$SHELL_PROMPT_USER_HOST "
fi;

PROMPT+=" $SHELL_PROMPT_DIR_INFO"

# Add git prompt info
PROMPT+=' $(git_prompt_info)'

# Set the default, to make it possible to reset after modifications.
PROMPT_DEFAULT=$PROMPT
