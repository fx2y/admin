#!/bin/bash
RESET_FONT="\033[0m"
BOLD="\033[1m"
YELLOW="\033[38;5;11m"
BLUE="\033[0;34m"
RED="\033[0;31m"
WHITE="\033[38;5;15m"

echo -e "${YELLOW}###### Setting up credentials${RESET_FONT}"
# demo-credentials.sh should contain:
#		GITLAB_NS=
#		GITHUB_NS=
#		GITHUB_USER=
#		IMG_NS=
#		GITHUB_TOKEN=
#		DOCKERHUB_USER=
#		DOCKERHUB_PWD=
#		ADMIN=<path to this repo>
source ~/demo-credentials.sh
if [[ -z "$GITHUB_NS" ]] \
|| [[ -z "$GITHUB_USER" ]] \
|| [[ -z "$IMG_NS" ]] \
|| [[ -z "$GITHUB_TOKEN" ]] \
|| [[ -z "$DOCKERHUB_USER" ]] \
|| [[ -z "$DOCKERHUB_PWD" ]] \
|| [[ -z "$ADMIN" ]]; then
    echo -e "${RED}${BOLD}Credentials not set! Create a correct demo-credentials.sh inside the home directory!${RESET_FONT}"
    return
fi

echo -e "${YELLOW}###### Setting up aliases${RESET_FONT}"
source ${ADMIN}/demos/aliases.sh

echo -e "${YELLOW}###### Get token to be able to talk to Docker Hub${RESET_FONT}"
DOCKERHUB_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USER}'", "password": "'${DOCKERHUB_PWD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

echo -e "${YELLOW}###### Setting up prompt${RESET_FONT}"
promptcol="$(tput sgr0)$(tput setaf 220)"
cmdcol="$(tput sgr0)$(tput bold)"
normalcol="$(tput sgr0)"
trap 'echo -n "$normalcol"' DEBUG
PS1="\n\[$promptcol\]\w\$ \[$cmdcol\]"

echo -e "${YELLOW}###### Setting up demorunner${RESET_FONT}"
export DEMO_DELAY=15
PATH=~/workspace-demo/demorunner:$PATH
