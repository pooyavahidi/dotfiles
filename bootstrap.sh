#!/bin/sh

# Check if the working directory is clean
__git_untracked_objects=$(git ls-files --others --directory)

# If previous command exited with error, return false
[[ $? != 0 ]] && return 1

if [[ -n $__git_untracked_objects ]]; then
    echo "Clean up the working directory before bootstrapping. Remove these:"
    echo $__git_untracked_objects
    return 1
fi
unset __git_untracked_objects

# Copy dotfiles and .lib directory
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
    # Copy settings for vscode in Linux
    if [ -d "$HOME/.config/Code/User" ]; then
        rsync -avh init/vscode/ $HOME/.config/Code/User
    fi
fi

# Source the rc file based on the current shell.
if [[ "$SHELL" =~ "zsh" ]]; then
   source ~/.zshrc
else
    source ~/.bashrc
fi
