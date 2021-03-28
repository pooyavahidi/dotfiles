# Set SHELL if it's empty
[[ -z $SHELL ]] && export SHELL='/bin/zsh'

# load the tab completion 
autoload -Uz compinit && compinit
# Allow zsh to read bash completions and run bash builtin function `complete`.
autoload bashcompinit && bashcompinit

# source the shell profile (shared between bash and zsh)
source ~/.shell_profile

# Setting the prompt similar to default macOS terminal prompt
export PROMPT="%F{green}%n@%m%f %1~ %# "
