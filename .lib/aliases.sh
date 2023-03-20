#!/bin/sh

# Some of these aliases are based on the solid work of @mathiasbynens.
# https://github.com/mathiasbynens/dotfiles/blob/main/.aliases


# Navigations
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# Shortcuts
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias ws="cd $WORKSPACE"
alias temp="cd $WORKSPACE/temp"

if [[ ${XDG_CURRENT_DESKTOP} =~ "GNOME" ]]; then
    # It's linux and running GNOME
    alias term="gnome-terminal"
    alias open="xdg-open"
fi

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
else # macOS `ls`
	colorflag="-G"
fi

# List all files colorized in long format
alias l="ls -lFh ${colorflag}"

# List all files colorized in long format, excluding . and ..
alias ll="ls -lAFh ${colorflag}"

# List all files 
alias la="ls -laF ${colorflag}"

# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"
 
# Always use color output for `ls`
alias ls="command ls ${colorflag}"

# Easier to clear screen and see the lists
alias cl="clear"
alias cll="clear && ls -lAFh ${colorflag}"

# Always enable colored `grep` output
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Always show tree in color
alias tree="tree -C"
