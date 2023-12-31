#!/bin/sh


# Print error to STDERR.
function __err() {
    echo -e "\e[1;31mERROR [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*\e[0m" >&2
}

# Return the path from QUICK_PATHS for the given alias.
function __get_quick_path() {
    local __alias="$1"
    local __path=""

    if [[ -z "${QUICK_PATHS}" ]]; then
        __err "QUICK_PATHS is empty or not defined"
        return 1
    fi

    if [[ -z "$__alias" ]]; then
        __err "alias is missing"
        return 1
    fi

    __path="${QUICK_PATHS[$__alias]}"

    # If the alias is not found, return an error.
    if [[ -z "${__path}" ]]; then
        __err "alias $__alias not found"
        return 1
    fi

    # If path is not a valid file or directory, return an error.
    if [[ ! -f "$__path" && ! -d "$__path" ]]; then
        __err "path $__path not found or valid for alias $__alias"
        return 1
    fi

    echo "$__path"
}
# Return the list of QUICK_PATHS aliases.
function __list_quick_paths() {
    if [[ -z "${QUICK_PATHS}" ]]; then
        __err "QUICK_PATHS is empty or not defined"
        return 1
    fi

    for __key in ${(k)QUICK_PATHS}; do
        printf "%s=%s\n" "$__key" "${QUICK_PATHS[$__key]}"
    done
}

# j is short for "jump", to quickly jump to a directory using quick path alias.
function j() {
    local __alias="$1"
    local __path=""

    __path=$(__get_quick_path "$__alias")
    (( $? != 0 )) && return 1

    if [[ -d "$__path" ]]; then
        # If the path is a directory, cd to that.
        cd "$__path" && pwd
    elif [[ -f "$__path" ]]; then
        # If the path is a file, cd to the parent directory.
        cd "$(dirname "$__path")" && pwd
    else
        __err "cannot cd to $__path"
        return 1
    fi
}

# c is short for code, and overrding the code command to use quick path alias.
function c() {
    local __alias="$1"
    local __path=""

    __path=$(__get_quick_path "$__alias" 2> /dev/null)
    if (( $? == 0 )); then
        # If the first argument is an alias, use the path for that alias.
        # Remove the first argument and pass the rest to code.
        shift 1
        command code "$__path" "$@"
    else
        # If the first argument is not an alias, then just run code as is.
        command code "$@"
    fi
}

# Combine jump and code to jc() function.
function jc() {
    j $1 && c $1
}

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
