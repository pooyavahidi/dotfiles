#!/bin/sh

# awscli completion
if __aws_comp=$(which aws_completer); then
    complete -C ${__aws_comp} aws
fi;
unset __aws_comp;
