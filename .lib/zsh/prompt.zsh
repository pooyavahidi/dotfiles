#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# Initial prefix and final suffix. Initial prefix shows green if previous
# command exited without error, otherwise shows red.
SHELL_PROMPT_INITIAL_PREFIX="%B%(?:%F{green}➜%f:%F{red}➜%f)%b"
SHELL_PROMPT_FINAL_SUFFIX=" "

# Git Prompt Info
SHELL_PROMPT_GIT_BRANCH_PREFIX=" %B%F{blue}(%f%F{red}"
SHELL_PROMPT_GIT_BRANCH_SUFFIX="%f%F{blue})%f%b "
SHELL_PROMPT_GIT_DIRTY="%F{yellow}✗%f"
SHELL_PROMPT_GIT_STATUS_PREFIX=""
SHELL_PROMPT_GIT_STATUS_SUFFIX=""
SHELL_PROMPT_GIT_AHEAD="%F{yellow}⇡%f"
SHELL_PROMPT_GIT_BEHIND="%F{yellow}⇣%f"

# user@hostname
SHELL_PROMPT_USER_HOST="%F{green}%n@%m%f"

# Current Directory info, to show the full path relative to HOME, replace %c with %~
SHELL_PROMPT_DIR_INFO="%B%F{cyan}%c%f%b"


# Set the PROMPT
#######################################
# To set the prompt to the MacOS default use the following:
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

PROMPT=$SHELL_PROMPT_INITIAL_PREFIX

# Show user@hostname if connected via SSH or it's inside a container.
if [[ "${SSH_TTY}" ]] || [[ "${SSH_CONNECTION}" ]] || _is_in_container; then
    PROMPT+=" $SHELL_PROMPT_USER_HOST"
fi;

PROMPT+=" $SHELL_PROMPT_DIR_INFO"

PROMPT+='$(git_prompt_info)'

PROMPT+=$SHELL_PROMPT_FINAL_SUFFIX
