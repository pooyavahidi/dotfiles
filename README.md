# dotfiles
A collection of .files and settings. The best way of using this repo is to fork and customize it as per your environment.

## How to customize without creating a fork
However, if you don't want to fork it, you can still customize it by just keeping all the customizations (aliases, settings and overrides) in `~/.extra` file. `bootstrap.sh` won't override that file.

## Dependencies
Some of the scripts using vanilla `python3` which is already being shipped with almost all decently recent distributions of macOS and Linux.

## Installation
Simply run the `bootstrap.sh` from the dotfiles directory.
```sh
git clone https://github.com/pooyavahidi/dotfiles.git
cd dotfiles
./bootstrap.sh
```

### macOS defaults

To set some sensible macOS defaults, run this after the bootstrapping.

```sh
./.macos
```
