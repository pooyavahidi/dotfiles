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
alias dcri="docker run -it"
alias dcrim="docker run -it --rm"
alias dcat="docker::container_attach"
alias dcs="docker container stop"
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

function docker::stats() {
    if [[ $# -eq 0 ]]; then
        docker container stats --no-stream;
    else
        docker container stats --no-stream | grep $1;
    fi
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
    c_status=$(docker container inspect $container | grep Status)

    # If error in getting the status, exit
    (( $? != 0 )) && return 1

    # Get the Status value
    c_status=$(echo $c_status | cut -d'"' -f 4)

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
            echo "Status is $c_status. Cannot attach!"
            return 1
            ;;
    esac
}
