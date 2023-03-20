#!/bin/sh


# Ping tcp ports 
function ping-tcp() {
    # $1 = host, $2 = port
    echo > /dev/tcp/$1/$2 && echo "$1:$2 is open."
}

# Ping udp ports
function ping-udp() {
    # $1 = host, $2 = port
    echo > /dev/udp/$1/$2 && echo "$1:$2 is open."
}

# A simple watch command replacement. It runs in the current shell 
# so all the aliases and sourced scripts are available.
function sw() {
    local __usage="sw -n <interval-in-sec> command"

    # If there is no argument provided, show usage and return
    if [[ $# -le 1 ]]; then
        echo $__usage
        return
    fi

    # Load the command line parameters into variables.
    while [ $# -gt 1 ]; do
        case $1 in
            -n)
                shift
                local __watch_interval=$1
                shift
                ;;
            *)
                break
                ;;
      esac
    done

    # If the command is empty show usage and return
    if [[ -z $1 ]]; then
        echo $__usage
        return
    fi

    # Run the given command in indefinite loop until user stops the process
    while true; do
        clear
        echo -e "$(date)\tRunning every ${__watch_interval} seconds."
        echo "---"
        eval "$@"
        sleep ${__watch_interval}
    done
}

# A shorthand for the grep command to search for a given string inside the files
# of the current directory recursively.
# exclude .git
function search-text() {
    local __pattern
    __pattern=$1

    # Validations
    [[ -z ${__pattern} ]] && __err "pattern is missing" && return 1

    grep --exclude-dir=.git -inr ${__pattern} .
}

# A shorthand for the find and grep command to search for a given string in
# files and directories names.
# excludes .git
function search-files() {
    local __pattern
    __pattern=$1

    # Validations
    [[ -z ${__pattern} ]] && __err "pattern is missing" && return 1

    find . ! -path "*/.git/*" | grep -i ${__pattern}
}

# Checksum for directories
function checksumdir() {
    local __dir
    local __option
    local __hash

    while [[ -n "$1" ]]; do
        case $1 in
            -g | --git)
                __option="git"
                shift
                ;;
             *)
                __dir=$1
                shift
                ;;
        esac
    done

    # If directory is not provided set it to current dir.
    [[ -z $__dir ]] && __dir="."


    if [[ "$__option" == "git" ]]; then
        __hash=$(git ls-files \
        | LC_ALL=C sort \
        | xargs shasum -a 256 \
        | shasum -a 256)
    else
        # By default, include all files.
        __hash=$(find $__dir -type f \
        | LC_ALL=C sort \
        | xargs shasum -a 256 \
        | shasum -a 256)
    fi
    echo $__hash | cut -d' ' -f1 | xargs printf "%s  $__dir\n"
}

# Returns true if the given value is an integer.
function is-int() {
    local int_regex
    int_regex="^[0-9]+$"

    if [[ $1 =~ $int_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Print error to STDERR.
function __err() {
    echo -e "\e[1;31mERROR [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*\e[0m" >&2
}
