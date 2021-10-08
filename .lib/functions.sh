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

# Create a new python project using scaffolding templates
function scaffold-python-project {
	python3 ${HOME}/.bin/python_scaffolding.py
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

#################################
# git related functions
#################################

# Creates patch files from the current git repository and save them into an S3
# bucket. It can download, upload and delete patches from the bucket.
function git-patch {
    # Validations
    if [[ -z $1 ]]; then
        echo "Usage: git-patch <save|load|clean>" && return
    fi

    declare -a __actions=(save load clean)
    for __available_action in "${__actions[@]}"; do
        [[ "$__available_action" == "$1" ]] && __action=$1
    done

    [[ -z ${__action} ]] && echo "action is not provided or valid" && return
    [[ -z ${S3_PATCHES_BUCKET} ]] && echo "S3_PATCHES_BUCKET is not set" \
        && return

    # Set the repo_name based on the origin url
    __repo_name=$(git config --get remote.origin.url | sed -e "s/:/_/g" | sed -e "s/\//_/g")
    __patch_prefix=${__repo_name}

    if [[ $__action == "save" ]]; then
        __patch_file=$(date +"%y%m%d_%H%M")

        # Compare the commit id of origin and local head, if they don't match
        # apply the soft reset to make the local committed-changes visible in
        # the staged state.

        # Find the commit number which remote origin is pointing to
        __origin_repo=origin/$(git branch --show-current)
        __origin_head=$(git log --oneline ${__origin_repo} | awk 'NR==1 {print $1}')

        # Find the commit number of the local head
        __local_head=$(git log --oneline | awk 'NR==1 {print $1}')

        if [[ ${__origin_head} == ${__local_head} ]]; then
            echo "Remote ${__origin_repo} and local head are the same"
        else
            # if local head is different, then local repo has local commits
            # Do the soft reset to get the all changes between local and remote
            echo -e "\e[32mRemote origin and local heads are different." \
                 "Soft reseting...\e[0m"
            git reset --soft ${__origin_head}
        fi

        # if there is any staged changes, save them to a file
        if [[ -n $(git diff --staged) ]]; then
            git diff --staged > ${__patch_file}.patch \
            && echo "patched to ${__patch_file}.patch"
        fi

        # If there is any file which is in the unstaged mode, pick them up too
        if [[ -n $(git diff) ]]; then
            git diff > ${__patch_file}_unstaged.patch \
            && echo "patched to ${__patch_file}_unstaged.patch"
        fi
    fi

    # Based on the action, upload, download or delete files from the S3 bucket
    case $__action in
        save)
            aws s3 cp . s3://${S3_PATCHES_BUCKET}/${__patch_prefix}/ \
                --recursive --exclude "*" --include "${__patch_file}*.patch"
            rm ${__patch_file}*.patch
            ;;
        load)
            aws s3 cp s3://${S3_PATCHES_BUCKET}/${__patch_prefix}/ . \
                --recursive
            ;;
        clean)
            aws s3 rm s3://${S3_PATCHES_BUCKET}/${__patch_prefix}/ \
                --recursive
            ;;
        *)
            echo "ERROR: unkown action"
            return
            ;;
    esac

    unset __repo_name __actions __action __available_action __patch_file \
         __patch_prefix __origin_head __local_head __origin_repo
}
