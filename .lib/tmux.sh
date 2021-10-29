#!/bin/sh


#######################################
# aliases
#######################################
alias t='tmux -u'
# tmux list of sessions
alias tl='tmux ls'
alias tkill='tmux kill-session -t'


#######################################
# functions
#######################################

function ta() {
    if [[ $# -eq 0 ]]; then
        # Attach to the last session
        tmux -u attach
    else
        # Try to attach to the given session, if doesn't exist, create a new one
        tmux -u attach -t $1 > /dev/null 2>&1 || tmux -u new-session -s $1
    fi
}

