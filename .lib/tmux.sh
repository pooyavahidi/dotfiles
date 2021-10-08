#!/bin/sh


#######################################
# aliases
#######################################
alias t='tmux -u'

# tmux list of sessions
alias tl='tmux ls'

# tmux attach to the last session
alias ta='tmux -u attach'

# tmux attach to session or create a new one
alias tat='tmux -u attach -t $1 > /dev/null 2>&1 || tmux -u new-session -s $1'


#######################################
# functions
#######################################

