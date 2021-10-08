#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# To set the prompt to the basic mode use the following.
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

SHELL_PROMPT_GIT_PREFIX=" %{$fg_bold[blue]%}(%{$fg[red]%}"
SHELL_PROMPT_GIT_SUFFIX=""
SHELL_PROMPT_GIT_DIRTY="%{$fg_bold[blue]%}) %{$fg[yellow]%}✗"
SHELL_PROMPT_GIT_CLEAN="%{$fg_bold[blue]%})"


# Shows the arrow. if the last command was successful, shows green, if error, red
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) "

# If connected via SSH, show the user@hostname
if [[ "${SSH_TTY}" ]] || [[ "${SSH_CONNECTION}" ]]; then
    PROMPT+="%{$fg[green]%}%n@%m "
fi;

# Show directory info
PROMPT+="%{$fg[cyan]%}%c"

# Add git status info
PROMPT+='$(git_prompt_info)'

# Reset the color for the user input
PROMPT+="%{$reset_color%} "
