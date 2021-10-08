#!/bin/sh


#######################################
# aliases
#######################################
alias d='docker'


#######################################
# functions
#######################################

function docker-prune-all(){
    docker container prune -f
    docker image prune -f -a
}

function docker-remove-containers {
    # Stop all the containers
    docker container ls | awk 'NR>1 {print $1}' | xargs docker container stop

    # Remove all the stopped containers
    docker container prune -f
}

function docker-remove-all {
    # Stop and remove all the containers
    docker-remove-containers

    # Remove all the images 
    docker image prune -f -a
}

function docker-restart {
    sudo systemctl restart docker
}

