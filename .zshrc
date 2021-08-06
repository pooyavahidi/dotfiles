# Set SHELL if it's empty
[[ -z $SHELL ]] && export SHELL='/bin/zsh'

# load the tab completions 
autoload -Uz compinit && compinit
# Allow zsh to read bash completions and run bash builtin function `complete`.
autoload bashcompinit && bashcompinit

# If kubectl exists, add its completion
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# source the shell profile (shared between bash and zsh)
source ~/.shell_profile

# Setting the prompt similar to default macOS terminal prompt
export PROMPT="%B%F{green}%n@%m%f %1~ %b%# "
