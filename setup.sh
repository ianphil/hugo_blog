#!/usr/bin/env bash

# Title:         setup.sh
# Description:   Setup blog with Hugo
# Author:        Ian Philpot <ian.philpot@microsoft.com>
# Date:          2018-12-08
# Version:       0.1.0

HUGO_UPDATED="hugo:updated"
HUGO_SETUP="hugo:setup"
HUGO_BASE="hugo:base"
HUGO_BUILDER="hugo:builder"
HUGO_SERVER="hugo:server"
SERVER_CONTAINER_NAME="hugo_server"

function log_red () {
    echo `tput setaf 1`$1`tput sgr0`
}

function log_green () {
    echo `tput setaf 2`$1`tput sgr0`
}



function build_images () {
    docker build -t $HUGO_UPDATED --target updated . > /dev/null 2>&1
    docker build -t $HUGO_SETUP --target setup . > /dev/null 2>&1
    docker build -t $HUGO_BASE --target base . > /dev/null 2>&1
    docker build -t $HUGO_BUILDER --target builder . > /dev/null 2>&1
    docker build -t $HUGO_SERVER --target server . > /dev/null 2>&1
    docker rmi $(docker images --filter "dangling=true" -q) > /dev/null 2>&1
    log_green "All Hugo images created"
}

function clean_images () {
    docker rmi $HUGO_UPDATED --force > /dev/null 2>&1
    docker rmi $HUGO_SETUP --force > /dev/null 2>&1
    docker rmi $HUGO_BASE --force > /dev/null 2>&1
    docker rmi $HUGO_BUILDER --force > /dev/null 2>&1
    docker rmi $HUGO_SERVER --force > /dev/null 2>&1
    log_red "All Hugo images removed"
}

function is_hugo_server_running () {
    IS_HUGO_SERVER="$(docker ps --filter "label=co.ianp.se.name=server" --format '{{.Label "co.ianp.se.name"}}')"
    IS_HUGO_SERVER=`echo -e "${IS_HUGO_SERVER}" |  sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'`

    if [[ "$IS_HUGO_SERVER" == "server" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function does_hugo_server_image_exist () {
    IS_HUGO_IMAGE=$(docker images --filter "label=co.ianp.se.name=server" --format {{.Tag}})
    IS_HUGO_IMAGE=`echo -e "${IS_HUGO_IMAGE}" |  sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'`

    if [[ "$IS_HUGO_IMAGE" == "server" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function stop_hugo_server () {
    docker rm $SERVER_CONTAINER_NAME --force > /dev/null 2>&1
}

function start_hugo_server () {
    HUGO_IMAGE_EXISTS=$(does_hugo_server_image_exist)

    if [[ "$HUGO_IMAGE_EXISTS" == "true" ]]; then
        docker run -d -v "$(pwd):/hugo" -p 80:1313 --name $SERVER_CONTAINER_NAME $HUGO_SERVER > /dev/null 2>&1
    else
        log_red "Hugo image for serve does not exist. Have you run --build?"
        exit 126 # Cmd cannot execute status -- get status afterward from shell `echo $?`
    fi
}

function start_or_stop_server () {
    HUGO_SERVER_RUNNING=$(is_hugo_server_running)

    if [[ "$HUGO_SERVER_RUNNING" == "true" ]]; then
        stop_hugo_server
        log_red "Hugo server stopped"
        
    else
        start_hugo_server
        log_green "Hugo server started"
        
    fi
}

POSITIONAL=()
while [[ $# > 0 ]]; do
    case "$1" in
        -b|--build)
        build_images
        shift
        ;;
        -c|--clean)
        clean_images
        shift
        ;;
        -s|--server)
        start_or_stop_server
        shift
        ;;
        -t|--switch)
        echo switch $1 with value: $2
        shift 2 # shift twice to bypass switch and its value
        ;;
        *) # unknown flag/switch
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional params

# docker run -v "$(pwd):/hugo" hugo:builder
