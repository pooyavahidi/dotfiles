#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# To set the prompt to the basic mode use the following.
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

# Set the arrow. green if successful, red if error
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) "

# If connected via SSH, show the user@hostname
if [[ "${SSH_TTY}" ]] || [[ "${SSH_CONNECTION}" ]]; then
    PROMPT+="%{$fg[green]%}%n@%m "
fi;

# Show directory info
PROMPT+="%{$fg[cyan]%}%c"

# Reset the color for the user input
PROMPT+="%{$reset_color%} "
