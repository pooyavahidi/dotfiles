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
alias dcatt="docker::container_attach"
alias dcip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
alias dcit="docker run -it"
alias dcitrm="docker run -it --rm"
alias dcl="docker container ls -a"
alias dcls="docker::get_containers"
alias dcrm="docker::remove_containers"
alias dcprune="docker container prune -f"
alias dcs="docker container stop"
alias dcsh="docker::exec_shell"
alias dcstats="docker container stats --no-stream"

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

# Run shell in the container interactively.
function docker::exec_shell() {
    local __container
    local __shell_in_container

    __container=$1

    # Check if container running
    if ! docker::get_container_status $__container | grep -wq running; then
        echo "Container $__container is not running."
        return 1
    fi

    # Check what is the default shell in the container
    __shell_in_container=$(docker exec $__container sh -c 'echo $SHELL')
    (( $? != 0 )) && return 1

    # If there is no default shell, fall back to `sh`
    if [ -z "$__shell_in_container" ]; then
        __shell_in_container="sh"
    fi

    docker exec -it $__container $__shell_in_container
}

# Get containers by their name pattern
function docker::get_containers() {
    local __pattern
    local __containers

    __pattern="$1"
    __containers=$(docker container ls -a --filter "name=${__pattern}" --format "{{.Names}}")

    echo $__containers
}

# Remove containers by an identifier (name pattern or image id).
function docker::remove_containers() {
    local __identifier

    __identifier="$1"

    # Check for provided identifier. We don't want to delete all containers!
    if [[ -z $__identifier ]]; then
        echo "Please provide an identifier."
        return 1
    fi

    # First check the containers name for this identifier.
    __containers=$(docker::get_containers $__identifier)

    if [[ -n "$__containers" ]]; then
        # If there are matching containers, then remove them all.
        echo $__containers | xargs docker container rm -f
    else
        # If no container found with the given identifier as name pattern,
        # assume it's an IMAGE ID, and try to remove it directly.
        docker container rm -f ${__identifier}
    fi
}

# Attach to a container. If it's not running, start it first.
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
