#!/bin/sh

#######################################
# environment variables
#######################################

# Enable docker BuildKit
export DOCKER_BUILDKIT=1
export DOCKER_LOCAL_REGISTRY="pv"


#######################################
# aliases
#######################################
alias d="docker"

# Containers
alias dcl="docker container ls -a"
alias dcit="docker run -it"
alias dcitrm="docker run -it --rm"
alias dcrm="docker container rm -f"
alias dcatt="docker::container_attach"
alias dcs="docker container stop"
alias dcstats="docker container stats --no-stream"
# Get container IP
alias dcip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
alias dcprune="docker container prune -f"

# Images
alias dil="docker image ls -a"
alias dirm="docker image rm"
alias diprune="docker image prune -f"

# Volumes
alias dvl="docker volume ls"

# System
alias dsprune="docker system prune -a --volumes"
alias dsdf="docker system df"


#######################################
# functions
#######################################

function docker::get_container_status() {
    local container
    local c_status

    container=$1
    c_status=$(docker container inspect $container | grep Status)

    # If error in getting the status, exit
    (( $? != 0 )) && return 1

    # Get the Status value
    c_status=$(echo $c_status | cut -d'"' -f 4)
    echo $c_status
}


# If path '/' is mounted to `overlay`, it's most likely inside a container
function docker::is_in_container() {
    if findmnt > /dev/null 2>&1 && \
        [[ $(findmnt / -o SOURCE | awk 'NR>1 {print $1}') == "overlay" ]]; then
            return 0
    else
        return 1
    fi
}

# Attach to an existing container.
# If it's not running, make it to run first, then attach to it.
function docker::container_attach() {
    local container
    local c_status

    container=$1
    # Try to get container status. If error, exit
    c_status=$(docker::get_container_status $container)
    (( $? != 0 )) && return 1

    case $c_status in
        running)
            docker container attach $container
            return 0
            ;;
        exited)
            docker container start $container
            docker container attach $container
            return 0
            ;;
        paused)
            docker container unpause $container
            docker container attach $container
            return 0
            ;;
        *)
            __err "Status is $c_status. Cannot attach!"
            return 1
            ;;
    esac
}
