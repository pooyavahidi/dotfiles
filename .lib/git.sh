#!/bin/sh


#######################################
# aliases
#######################################

alias g="git"
alias g-patch-push="git::__patch save && git::__patch_repo_sync"
alias g-patch-pull="git::__patch_repo_sync && git::__patch load && git::__patch clean"
alias g-push-all-changes="git::push_all_changes"


#######################################
# functions
#######################################

# Creates/saves/loads patch files from the current git repository.
function git::__patch() {
    local -a __actions
    local __action
    local __available_action
    local __patch_file
    local __patch_prefix
    local __origin_head
    local __local_head
    local __origin_repo

    # Validations
    if ! git::is_git_working_dir; then
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

    # Get the minified version of the remote url
    __patch_prefix=$(git::remote_url_minified)
    [[ -z __patch_prefix ]] && echo "Unable to read remote url" && return 1

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

# It goes to the patches working dir and then push all the changes.
# This function should run from the git working directory which the patch has
# been created for.
function git::__patch_repo_sync() {
    local __orig_dir

    __orig_dir=$(pwd)

    cd ${PATCHES_REPO} \
    && git pull

    if (( $? != 0 )); then
        cd $__orig_dir
        return 1
    fi

    git::push_all_changes "patches" \
    && cd $__orig_dir
}

# Pull and then push all the changes.
function git::push_all_changes() {
    local commit_msg

    commit_msg=$1
    [[ -z $commit_mdg ]] && commit_msg="update"

    git pull \
    && git add .

    # Check to see if there is any changes in the working directory or index.
    if ! ( git diff --quiet --cached && git diff --quiet ); then
        git commit -m "$commit_msg" \
        && git push
    else
        echo "There are no changes to push!"
    fi
}

# git prompt functions are inspired by ohmyzsh and spaceship-prompt libraries.
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh
# https://github.com/spaceship-prompt/spaceship-prompt

# Wrap in a local function instead of exporting the variable directly in
# order to avoid interfering with manually-run git commands by the user.
function git::__prompt_git() {
    GIT_OPTIONAL_LOCKS=0 command git "$@"
}

function git::prompt_info() {
    # If we are on a directory not tracked by git, get out.
    # Otherwise, check for hide-info at global and local repository level
    if ! git::__prompt_git rev-parse --git-dir &> /dev/null; then
        return 0
    fi

    local ref
    ref=$(git::__prompt_git symbolic-ref --short HEAD 2> /dev/null) \
    || ref=$(git::__prompt_git rev-parse --short HEAD 2> /dev/null) \
    || return 0

    local prompt_info
    prompt_info="${SHELL_PROMPT_GIT_BRANCH_PREFIX}${ref}"
    prompt_info+="${SHELL_PROMPT_GIT_BRANCH_SUFFIX}$(git::__parse_git_status)"

    echo $prompt_info
}

# Check the git status and return the status prompt and the dirty flag
function git::__parse_git_status() {
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

    STATUS=$(git::__prompt_git status ${FLAGS} 2> /dev/null)

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

    # Add dirty flag to the status prompt
    if [[ "$is_dirty" == true ]]; then
        # If status prompt is not empty, add a space in front.
        if [[ -n $status_prompt ]]; then
            status_prompt+=" "
        fi
        status_prompt+=$SHELL_PROMPT_GIT_DIRTY
    fi

    if [[ -n "$status_prompt" ]]; then
        # If status_prompt is not empty, set it with prefix and suffix
        echo ${SHELL_PROMPT_GIT_STATUS_PREFIX}${status_prompt}${SHELL_PROMPT_GIT_STATUS_SUFFIX}
    else
        return 0
    fi
}

# If the given directory is a git working directory return 0, if not return 1
function git::is_git_working_dir() {
    local __dir
    __dir=$1

    # If no directory has been passed, use the current directory
    if [[ -z $__dir ]]; then
        # If no directory is given, then assume it's the current directory.
        if git::__prompt_git rev-parse --git-dir &> /dev/null; then
            return 0
        else
            return 1
        fi
    fi

    # If a directory is given, then use its .git directory path.
    if ! git::__prompt_git --git-dir=$__dir/.git \
        rev-parse --git-dir &> /dev/null; then
        return 1
    fi
}

# Returns a minified version of the remote url and replace all
# special characters with `_`.
function git::remote_url_minified() {
    local __remote_url
    __remote_url=$(git config --get remote.origin.url)

    # If previous command exited with error, then do the same
    (( $? != 0 )) && return 1

    # Remove the special characters, username and protocol from the origin url.
    # It works for both https and ssh
    echo $__remote_url \
        | sed -e "s/https:\/\///g" \
        | sed -e "s/.*@//g" \
        | sed -e "s/\//_/g" \
        | sed -e "s/:/_/g"
}

# Check for git status of all the subdirectories of the given path.
# This function goes through the first-level subdirectories.
function git::working_dir_status {
    local __dir

    __dir=$1
    [[ -z $__dir ]] && __dir=$(pwd)

    # If the directory is not tracked by git, then return
    if ! git::is_git_working_dir $__dir ; then
        return 1
    fi

    git::__prompt_git --work-tree=$__dir --git-dir=$__dir/.git \
        fetch

    git::__prompt_git --work-tree=$__dir --git-dir=$__dir/.git \
        status --short --branch
}
