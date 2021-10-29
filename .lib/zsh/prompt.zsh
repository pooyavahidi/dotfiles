#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# To set the prompt to the basic mode use the following.
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

SHELL_PROMPT_GIT_BRANCH_PREFIX=" %{$fg_bold[blue]%}(%{$fg[red]%}"
SHELL_PROMPT_GIT_BRANCH_SUFFIX="%{$fg_bold[blue]%})"
SHELL_PROMPT_GIT_DIRTY=" %{$fg[yellow]%}✗"
SHELL_PROMPT_GIT_STATUS_PREFIX=" "
SHELL_PROMPT_GIT_STATUS_SUFFIX=""
SHELL_PROMPT_GIT_AHEAD="%{$fg[yellow]%}⇡"
SHELL_PROMPT_GIT_BEHIND="%{$fg[yellow]%}⇣"

# Shows the arrow. if the last command was successful, shows green, if error, red
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) "

# Show the user@hostname if:
# connected via SSH or it's inside a container
if [[ "${SSH_TTY}" ]] || [[ "${SSH_CONNECTION}" || _is_in_container; then
    PROMPT+="%{$fg[green]%}%n@%m "
fi;

# Show directory info
# To show the full path relative to HOME, replace %c with %~
PROMPT+="%{$fg[cyan]%}%c"

# Add git prompt info
PROMPT+='$(git_prompt_info)'

# Reset the color for the user input
PROMPT+="%{$reset_color%} "
