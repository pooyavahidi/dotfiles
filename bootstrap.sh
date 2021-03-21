#!/bin/bash

# Copy dotfiles and bin/ directory
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
	
# Copy settings for vscode in Linux
if [ -d "$HOME/.config/Code/User" ]; then
	rsync -avh init/vscode/ $HOME/.config/Code/User
fi

# Copy settings for vscode in macOS
if [ -d "$HOME/Library/Application Support/Code/User" ]; then
	rsync -avh init/vscode/ "$HOME/Library/Application Support/Code/User" 
fi