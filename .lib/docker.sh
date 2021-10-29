#!/bin/sh

#######################################
# environment variables
#######################################

# Enable docker BuildKit
export DOCKER_BUILDKIT=1


#######################################
# aliases
#######################################
alias d="docker"
alias dcl="docker container ls -a"
alias dil="docker image ls -a"
alias dcrm="docker container rm"
alias dirm="docker image rm"
alias dvl="docker volume ls"

# Get container IP
alias dcip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Prune images
alias diprune="docker image prune -a -f"

# Prune containers
alias dcprune="docker container prune -f"

# Remove unused data
alias dsysprune="docker system prune -a --volumes"


#######################################
# functions
#######################################

# Stop all containers
function dcstop () {
    docker container stop $(docker container ls -a -q)
}

# Restart docker service
function drestart () {
    sudo systemctl restart docker
}

function dcstats() {
    if [[ $# -eq 0 ]]; then
        docker container stats --no-stream;
    else
        docker container stats --no-stream | grep $1;
    fi
}

# If path '/' is mounted to `overlay`, it's most likely inside a container
function _is_in_container() {
    if findmnt > /dev/null 2>&1 && \
        [[ $(findmnt / -o SOURCE | awk 'NR>1 {print $1}') == "overlay" ]]; then
            return 0
    else
        return 1
    fi
}

