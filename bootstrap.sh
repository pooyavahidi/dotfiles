#!/bin/bash


# Dictionary for name of config files and their temp file path.
declare -A bootstrap_config_map

function create_temp_files() {
    local prefix="/tmp/$(date +%s)"
    local gitconfig_temp_file="${prefix}_gitconfig.tmp"

    touch "$gitconfig_temp_file"
    bootstrap_config_map[".gitconfig"]="$gitconfig_temp_file"
}

function remove_temp_files() {
    for temp_file in "${bootstrap_config_map[@]}"; do
        [[ -f "$temp_file" ]] && rm -f "$temp_file"
    done

    # Clear the dictionary variable after cleanup.
    unset bootstrap_config_map
}

function pre_bootstrap() {
    local __git_untracked_objects

    # Check for any untracked objects and return an error if any.
    __git_untracked_objects=$(git ls-files --others --directory)
    (( $? != 0 )) && return 1

    if [[ -n $__git_untracked_objects ]]; then
        echo "Clean up the working directory before bootstrapping. Remove these:"
        echo $__git_untracked_objects
        return 1
    fi

    # Create temporary files for specific configs.
    create_temp_files

    # Process .gitconfig file.
    local gitconfig_temp_file=${bootstrap_config_map[".gitconfig"]}
    if [[ -f "$HOME/.gitconfig" ]] && [[ -n $gitconfig_temp_file ]]; then
        if type git &> /dev/null; then
            # Extract machine-specific settings, and
            # ignore errors if a particular pattern doesn't match.
            git config --file "$HOME/.gitconfig" \
                --get-regexp "^user\." > "$gitconfig_temp_file" || true
            git config --file "$HOME/.gitconfig" \
                --get-regexp "^credential\." >> "$gitconfig_temp_file" || true
        fi
    fi
}

function post_bootstrap() {
    local gitconfig_temp_file=${bootstrap_config_map[".gitconfig"]}

    # If the temporary gitconfig file exists, append its content to the .gitconfig.
    if [[ -f "$gitconfig_temp_file" ]]; then
        if type git &> /dev/null; then
            while IFS= read -r line; do
                local key=$(echo "$line" | cut -d ' ' -f 1)
                local value=$(echo "$line" | cut -d ' ' -f 2-)
                git config --file "$HOME/.gitconfig" "$key" "$value"
            done < "$gitconfig_temp_file"
        fi
    fi

    # Cleanup temporary files after bootstrap.
    remove_temp_files
}


function bootstrap() {
    rsync --exclude ".git/" \
        --exclude ".vscode/" \
        --exclude "init/" \
        --exclude ".DS_Store" \
        --exclude "*.swp" \
        --exclude "README.md" \
        --exclude ".gitignore" \
        --exclude ".osx" \
        --exclude ".macos" \
        --exclude "LICENSE" \
        --exclude "bootstrap.sh" \
        -avh . ~

    # Run OS specific bootstrap scripts
    if [[ $(uname -s) =~ "Darwin" ]]; then
        # Run macOS specific scripts
        ./.macos
    else
        # Run linux specific scripts
        if [ -d "$HOME/.config/Code/User" ]; then
            rsync -avh init/vscode/ $HOME/.config/Code/User
        fi
    fi
}

pre_bootstrap
(( $? != 0 )) && return 1

bootstrap
(( $? != 0 )) && return 1

post_bootstrap
(( $? != 0 )) && return 1

echo "\nBootstrapping completed successfully"

# After successful bootstrapping, source the RC file based on the current shell.
if [[ "$SHELL" =~ "zsh" ]]; then
    source "$HOME/.zshrc"
elif [[ "$SHELL" =~ "bash" ]]; then
    source "$HOME/.bashrc"
else
    echo "\nUnable to source RC file for unsupported shell `$SHELL`"
fi
