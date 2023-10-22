# Set SHELL
export SHELL='/bin/zsh'

# Load the tab completions
autoload -Uz compinit && compinit
# Allow zsh to read bash completions and run bash builtin function `complete`.
autoload bashcompinit && bashcompinit
# Load the colors
autoload colors && colors

# QUICK_PATHS stores alias/path pairs for quick access.
typeset -A QUICK_PATHS

# Load the shell profile (shared between bash and zsh)
source $HOME/.shell_profile

# Deduplicate path variable
typeset -U path

# Avoid duplicates and commands starting with a space in history.
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE

# Set the history size.
HISTSIZE=1000

# Load zsh scripts from the .lib directory
for file in $HOME/.lib/zsh/*.zsh; do
     source "$file"
done;
unset file;
