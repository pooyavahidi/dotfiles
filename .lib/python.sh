#!/bin/sh


#######################################
# aliases
#######################################
alias python="python3"
alias py="python3"


#######################################
# functions
#######################################
# Create a new python project using scaffolding templates
function python::scaffold_project() {
    python3 ${HOME}/.lib/python/python_scaffolding.py
}

