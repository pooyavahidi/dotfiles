# Set the SHELL
export SHELL='/bin/bash'

source ~/.shell_profile

# Add bash specific here

# If not running interactively, don't do anything and return early.
case $- in
    *i*) ;;
      *) return;;
esac

# Ignore duplicates and commands starting with a space in history.
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Load bash scripts from the .lib directory
for file in $HOME/.lib/bash/*.bash; do
     source "$file"
done;
unset file;

