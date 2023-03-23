#!/bin/sh

# MacOS specific aliases and overrides

alias md5sum="md5"
alias sha256sum="shasum -a 256"
alias term="open -a Terminal ."
alias uuidgen="uuidgen | tr 'A-Z' 'a-z'"
alias appverify="codesign -dv --verbose=4"
