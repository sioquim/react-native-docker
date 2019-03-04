#!/bin/bash

# get the ENV variable defined for docker
# and use the env in the current script
set -a
source ./.env 
set +a
export HOST_PATH=$(pwd)

# get our arguments
POSITIONAL=()
COMMANDS=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --build)
        COMMANDS+="docker-compose -p ${PROJECT_ID} -f ./docker-compose.yml build --no-cache"
        shift # past argument
        ;;

        -c|--command)
        shift # past argument
        SHELL_COMMAND=$1
        shift # past argument
        ;;

        *) # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# if we have no command (like for instance passed by the CI) just run zsh
if [ -z "${SHELL_COMMAND}" ]; then
    echo "No command passed";
    echo "docker-compose -p ${PROJECT_ID} -f ./docker-compose.yml up -d && docker exec -it ${PROJECT_ID} zsh";
    COMMANDS+=("docker-compose -p fetcham -f ./docker-compose.yml up -d && docker exec -it ${PROJECT_ID} zsh")
# otherwise execute the command
else
    # add the up and exec
    echo "docker-compose -p ${PROJECT_ID} -f ./docker-compose.yml up -d && docker exec -it ${PROJECT_ID} zsh -c \"${SHELL_COMMAND}\"";
    COMMANDS+=("docker-compose -p ${PROJECT_ID} -f ./docker-compose.yml up -d && docker exec -it ${PROJECT_ID} zsh -c \"${SHELL_COMMAND}\"")
fi

# join the commands in a string and execute
COMMAND_STRING=$(printf " && %s" "${COMMANDS[@]}")
COMMAND_STRING=${COMMAND_STRING:3}
eval "${COMMAND_STRING}"