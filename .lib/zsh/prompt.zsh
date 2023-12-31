#!/bin/zsh

# Enable parameter expansion, command substitution in prompts.
setopt PROMPT_SUBST

# Add text to the Right Prompt.
function __rprompt_add_text() {
    local __msg

    [[ -z "${__msg:=$1}" ]] && __err "message is not provided" && return 1

    # Decorate the message.
    __msg="[$__msg]"

    # Add delimiter between messages.
    if [[ -n $RPROMPT ]]; then
        __msg="-$__msg"
    fi

    # Add the final message to the RPROMPT with formatting.
    RPROMPT=$RPROMPT"%K{blue}$__msg%k"
}

# Initial prefix and final suffix. Initial prefix shows green if previous
# command exited without error, otherwise shows red.
SHELL_PROMPT_INITIAL_PREFIX="%B%(?:%F{green}➜%f:%F{red}${emoji[right_arrow_small]}%f)%b"
SHELL_PROMPT_FINAL_SUFFIX=" "

# Git Prompt Info
SHELL_PROMPT_GIT_BRANCH_PREFIX=" %B%F{blue}(%f%F{red}"
SHELL_PROMPT_GIT_BRANCH_SUFFIX="%f%F{blue})%f%b"
SHELL_PROMPT_GIT_DIRTY="%F{yellow}${emoji[cross_mark_small]}%f"
SHELL_PROMPT_GIT_STATUS_PREFIX=" "
SHELL_PROMPT_GIT_STATUS_SUFFIX=""
SHELL_PROMPT_GIT_AHEAD="%F{yellow}${emoji[up_arrow_dotted]}%f"
SHELL_PROMPT_GIT_BEHIND="%F{yellow}${emoji[down_arrow_dotted]}%f"

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
if [[ -n "${SSH_TTY}" ]] || [[ -n "${SSH_CONNECTION}" ]] \
    || docker::is_in_container; then

    PROMPT+=" $SHELL_PROMPT_USER_HOST"
fi;

PROMPT+=" $SHELL_PROMPT_DIR_INFO"

PROMPT+='$(git::prompt_info)'

PROMPT+=$SHELL_PROMPT_FINAL_SUFFIX
