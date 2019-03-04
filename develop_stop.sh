#!/bin/bash

# use the env in the current script
set -a
source ./.env 
set +a

HOST_PATH="$(pwd)" docker-compose -p ${PROJECT_ID}  -f ./docker-compose.yml down