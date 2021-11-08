#!/bin/sh

# Copy dotfiles and .lib directory
rsync --exclude ".git/" \
    --exclude ".vscode/" \
    --exclude "init/" \
    --exclude ".DS_Store" \
    --exclude "*.swp" \
    --exclude "README.md" \
    --exclude ".gitignore" \
    --exclude ".osx" \
    --exclude "LICENSE" \
    --exclude "bootstrap*" \
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
