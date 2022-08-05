#!/bin/sh


#######################################
# aliases
#######################################

alias g="git"
alias gpload="__git_patch load && __git_patch clean"
alias gpsave="__git_patch save"
alias gpclean="__git_patch clean"

#######################################
# functions
#######################################

# Creates patch files from the current git repository and save them into an S3
# bucket. It can download, upload and delete patches from the bucket.
function __git_patch {
    local __repo_name 
    local -a __actions 
    local __action 
    local __available_action 
    local __patch_file
    local __patch_prefix 
    local __origin_head 
    local __local_head 
    local __origin_repo

    # Validations
    if ! __is_git_working_dir; then
        echo "Not a git working directory" && return 1
    fi
    if [[ -z $1 ]]; then
        echo "Usage: git-patch <save|load|clean>" && return
    fi

    __actions=(save load clean)
    for __available_action in "${__actions[@]}"; do
        [[ "$__available_action" == "$1" ]] && __action=$1
    done

    [[ -z ${__action} ]] && echo "action is not provided or valid" && return
    [[ -z ${PATCHES_REPO} ]] && echo "PATCHES_REPO is not set" \
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
            # Create a directory in the patch repo if doesn't exist already
            [[ ! -d ${PATCHES_REPO}/${__patch_prefix} ]] \
                && mkdir ${PATCHES_REPO}/${__patch_prefix}

            # Check if patch files are created, then copy and clean up
            if [[ -n $(find . -type f -name "${__patch_file}*.patch") ]]; then
                cp ${__patch_file}*.patch ${PATCHES_REPO}/${__patch_prefix}/
                rm ${__patch_file}*.patch
            fi
            ;;
        load)
            cp -v ${PATCHES_REPO}/${__patch_prefix}/*.* .
            ;;
        clean)
            rm ${PATCHES_REPO}/${__patch_prefix}/*.*
            ;;
        *)
            echo "ERROR: unknown action"
            return
            ;;
    esac

}

# git prompt functions are inspired by ohmyzsh and spaceship-prompt libraries.
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh
# https://github.com/spaceship-prompt/spaceship-prompt

# Wrap in a local function instead of exporting the variable directly in
# order to avoid interfering with manually-run git commands by the user.
function __git_prompt_git() {
    GIT_OPTIONAL_LOCKS=0 command git "$@"
}

function git_prompt_info() {
    # If we are on a directory not tracked by git, get out.
    # Otherwise, check for hide-info at global and local repository level
    if ! __git_prompt_git rev-parse --git-dir &> /dev/null; then
        return 0
    fi

    local ref
    ref=$(__git_prompt_git symbolic-ref --short HEAD 2> /dev/null) \
    || ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) \
    || return 0

    local prompt_info
    prompt_info="${SHELL_PROMPT_GIT_BRANCH_PREFIX}${ref}"
    prompt_info+="${SHELL_PROMPT_GIT_BRANCH_SUFFIX}$(__parse_git_status)"

    echo $prompt_info
}

# Check the git status and return the status prompt and the dirty flag
function __parse_git_status() {
    local STATUS
    local -a FLAGS
    FLAGS=('--porcelain' '--branch')
    if [[ "${DISABLE_UNTRACKED_FILES_DIRTY:-}" == "true" ]]; then
        FLAGS+='--untracked-files=no'
    fi
    case "${GIT_STATUS_IGNORE_SUBMODULES:-}" in
        git)
            # let git decides (this respects per-repo config in .gitmodules)
            ;;
        *)
            # if unset: ignore dirty submodules
            # other values are passed to --ignore-submodules
            FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"
            ;;
    esac

    STATUS=$(__git_prompt_git status ${FLAGS} 2> /dev/null)

    local is_dirty=false
    # Remove the first line (branch info) from the status output and then 
    # check if the last line has some value. If yes, then it is dirty.
    if [[ -n $(echo "$STATUS" | sed "1d" | tail -1 2> /dev/null) ]]; then
        is_dirty=true
    fi

    local status_prompt

    # Check if branch is ahead
    if $(echo "$STATUS" | grep '^## [^ ]\+ .*ahead' &> /dev/null); then
        status_prompt+=$SHELL_PROMPT_GIT_AHEAD
    fi

    # Check if branch is behind
    if $(echo "$STATUS" | grep '^## [^ ]\+ .*behind' &> /dev/null); then
        status_prompt+=$SHELL_PROMPT_GIT_BEHIND
    fi

    # Set the status prompt with prefix and suffix
    if [[ -n $status_prompt ]]; then
        status_prompt=$SHELL_PROMPT_GIT_STATUS_PREFIX${status_prompt}
        status_prompt+=${SHELL_PROMPT_GIT_STATUS_SUFFIX}
    fi 

    # Add dirty flag to the status prompt
    if [[ "$is_dirty" == true ]]; then
        status_prompt="${status_prompt}$SHELL_PROMPT_GIT_DIRTY"
    fi

    if [[ -n "$status_prompt" ]]; then
        echo $status_prompt
    else
        return 0
    fi
}
# If the given directory is a git working directory return 0, if not return 1
function __is_git_working_dir() {
    local __dir
    __dir=$1

    # If no directory has been passed, use the current directory
    if [[ -z $__dir ]] && __dir=$(pwd)

    if ! __git_prompt_git --work-tree=$__dir --git-dir=$__dir/.git \
        rev-parse --git-dir &> /dev/null; then
        return 1
    fi
}

# Check for git status of all the subdirectories of the given path.
# This function goes through the first-level subdirectories.
function git_working_dirs_status {
    local __root_dir
    local __dir

    __root_dir=$1
    if [[ -z $__root_dir ]] && echo "Path is missing" && return 1

    # Go through all the first-level subdirectories of the given path
    for __dir in ${__root_dir}/*/ ; do
        # If the directory is not tracked by git, then continue
        if ! __is_git_working_dir $__dir ; then
            continue
        fi
        echo ----------------------------------------
        echo ${__dir}

        __git_prompt_git --work-tree=$__dir --git-dir=$__dir/.git \
            fetch

        __git_prompt_git --work-tree=$__dir --git-dir=$__dir/.git \
            status --short --branch
    done
}
