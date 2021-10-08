#!/bin/sh

# Open a new terminal
function term () {
	# If macos then use open command
	if [[ $(uname -s) =~ "Darwin" ]]; then
		open -a Terminal .
	# If gnome then use gnome command
	elif [[ ${XDG_CURRENT_DESKTOP} =~ "GNOME" ]]; then
		gnome-terminal
	fi
}

# Open the graphical files explorer 
function open-files {
    dir=$1
    [[ -z $dir ]] && dir='.'

    # If it's macOS
	if [[ $(uname -s) =~ "Darwin" ]]; then
		open $dir
    # If it's gnome
	elif [[ ${XDG_CURRENT_DESKTOP} =~ "GNOME" ]]; then
		xdg-open $dir
	fi
	unset dir;
}

# Ping tcp ports 
function ping-tcp {
    # $1 = host, $2 = port
    echo > /dev/tcp/$1/$2 && echo "$1:$2 is open."
}

# Ping udp ports
function ping-udp {
    # $1 = host, $2 = port
    echo > /dev/udp/$1/$2 && echo "$1:$2 is open."
}

# A simple watch command replacement. It runs in the current shell 
# so all the aliases and sourced scripts are available.
function sw {
    local __usage="sw -n <interval-in-sec> command"

    # If there is no argument provided, show usage and return
    if [[ $# -le 1 ]]; then
        echo $__usage
        return
    fi

    # Load the command line parameters into variables                               
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

