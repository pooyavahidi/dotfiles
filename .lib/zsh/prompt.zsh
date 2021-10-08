#!/bin/sh

# Enable parameter expansion, command substitution in prompts
setopt PROMPT_SUBST

# To set the prompt to the basic mode use the following.
# PROMPT="%B%F{green}%n@%m%f %1~ %b%# "

# Set the zsh prompt 
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT+=" %{$fg[cyan]%}%c%{$reset_color%} "
