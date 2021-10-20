#!/bin/sh


#######################################
# aliases
#######################################

alias python="python3"


#######################################
# functions
#######################################

# Create a new python project using scaffolding templates
function scaffold-python-project {
    python3 ${HOME}/.lib/python/python_scaffolding.py
}

