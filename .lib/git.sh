#!/bin/sh


#######################################
# aliases
#######################################

alias g="git"



#######################################
# functions
#######################################

# Create a new python project using scaffolding templates
function scaffold-python-project {
	python3 ${HOME}/.bin/python_scaffolding.py
}

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

