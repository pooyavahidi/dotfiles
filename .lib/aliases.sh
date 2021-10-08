#!/bin/sh

# This file is based on the solid work of @mathiasbynens, thanks!
# https://github.com/mathiasbynens/dotfiles/blob/main/.aliases

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
else # macOS `ls`
	colorflag="-G"
fi

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
alias g="git"
alias python="python3"

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

# Quick notes in vscode
alias qn='code ${WORKSPACE}/quick_notes/$(date +"%y%m%d_%H%M%S").md'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'


