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
alias dcattach="docker::container_attach"
alias dcip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
alias dcl="docker container ls -a"
alias dcln="docker::container_list"
alias dcrm="docker::container_remove"
alias dcprune="docker container prune -f"
alias dcsh="docker::exec_shell"
alias dcstats="docker container stats --no-stream"
alias dcstop="docker container stop"

# Container run
alias drit="docker run -it"
alias dritpwd='docker run -it -v "$(pwd):/workspace"'
alias dritrm="docker run -it --rm"
alias dritrmpwd='docker run -it --rm -v "$(pwd):/workspace"'

# Images
alias dil="docker image ls -a"
alias dirm="docker image rm"
alias diprune="docker image prune -f"

# Volumes
alias dvl="docker volume ls"

# System
alias dsprune="docker system prune -a --volumes"
alias dsdf="docker system df"

# Compose
alias dcomp="docker compose"
alias dcompf="docker::compose_config_files"

# Network
alias dnl="docker network ls"
alias dnrm="docker network rm"

# Logs
alias dclogs="docker container logs"


#######################################
# functions
#######################################

function docker::container_status() {
    local __container
    local __c_status

    __container=$1
    __c_status=$(docker container inspect $__container | grep Status)

    # If error in getting the status, exit
    (( $? != 0 )) && return 1

    # Get the Status value
    __c_status=$(echo $__c_status | cut -d'"' -f 4)
    echo $__c_status
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

    # Start the container if it's not.
    docker::container_start $__container
    (( $? != 0 )) && return 1

    # Check what is the default shell in the container.
    __shell_in_container=$(docker exec $__container sh -c 'echo $SHELL')
    (( $? != 0 )) && return 1

    # If there is no default shell, fall back to `sh`
    if [ -z "$__shell_in_container" ]; then
        __shell_in_container="sh"
    fi

    docker exec -it $__container $__shell_in_container
}

# Get list of container names by their name pattern.
function docker::container_list() {
    local __pattern
    local __containers

    __pattern="$1"
    __containers=$(docker container ls -a --filter "name=${__pattern}" --format "{{.Names}}")

    echo $__containers
}

# Remove containers by an identifier (name pattern or image id).
function docker::container_remove() {
    local __identifier

    __identifier="$1"

    # Check for provided identifier. We don't want to delete all containers!
    if [[ -z $__identifier ]]; then
        echo "Please provide an identifier."
        return 1
    fi

    # First check the containers name for this identifier.
    __containers=$(docker::container_list $__identifier)

    if [[ -n "$__containers" ]]; then
        # If there are matching containers, then remove them all.
        echo $__containers | xargs docker container rm -f
    else
        # If no container found with the given identifier as name pattern,
        # assume it's an IMAGE ID, and try to remove it directly.
        docker container rm -f ${__identifier}
    fi
}

# Try to start the container based on its status.
function docker::container_start() {
    local __container
    local __c_status

    __container=$1
    # Get container status. If error, exit.
    __c_status=$(docker::container_status $__container)
    (( $? != 0 )) && return 1

    case $__c_status in
        running)
            return 0
            ;;
        exited)
            echo "Starting $__container ..."
            docker container start $__container
            return 0
            ;;
        paused)
            echo "Unpausing $__container ..."
            docker container unpause $__container
            return 0
            ;;
        *)
            __err "Cannot start container $__container with status $__c_status"
            return 1
            ;;
    esac
}

function docker::container_attach() {
    local __container

    __container=$1

    # Start the container if it's not.
    docker::container_start $__container
    (( $? != 0 )) && return 1

    docker container attach $__container
}

# Get the docker-compose config file for containers matching the given name.
# If no name is given, it lists all containers with at least one config file.
function docker::compose_config_files() {
    declare -a __containers
    local __config_files
    local __num_config_files

    # Get all the container names matching the given name pattern.
    IFS=$'\n' __containers=($(docker::container_list $1))

    # If no containers matched, print a message and exit.
    if [ ${#__containers[@]} -eq 0 ]; then
        __err "No matching container found." && return 1
    fi

    # Header
    printf "%-40s %-7s %-60s\n" "CONTAINER NAME" \
           "FILES" "FIRST DOCKER-COMPOSE CONFIG FILE"

    # Use docker inspect to fetch the config_files label from each container.
    for __container in "${__containers[@]}"; do
        __config_files=$(
            docker inspect --format \
            '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' \
            "$__container" 2>/dev/null
        )

        # Count number of config files.
        __num_config_files=$(echo "$__config_files" | tr ',' '\n' | wc -l)

        # Take the first config file if there are multiple.
        IFS=',' read -r __config_file _ <<< "$__config_files"

        # If docker inspect returns a non-empty result, print it.
        if [ -n "${__config_file}" ]; then
            echo "$__container $__num_config_files $__config_file" \
            | awk '{printf "%-40s %-7s %-60s\n", $1, $2, $3}'

        fi
    done
}
