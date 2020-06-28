#!/bin/bash
RESET_FONT="\033[0m"
PURPLE="\033[0;35m"

echo -e "${PURPLE}###### Sourcing credentials${RESET_FONT}"
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

echo -e "${PURPLE}###### Removing repos locally${RESET_FONT}"
rm -rf ~/workspace-demo/go-demo-app
rm -rf ~/workspace-demo/go-demo-app-ops

echo -e "${PURPLE}###### Resetting APP repo${RESET_FONT}"
cd ~/workspace-demo
git clone https://github.com/springone-tour-2020-cicd/go-demo-app.git && cd go-demo-app
git reset --hard b25ac4b
git push -f
cd ~/workspace-demo

echo -e "${PURPLE}###### Resetting OPS repo${RESET_FONT}"
git clone https://github.com/springone-tour-2020-cicd/go-demo-app-ops.git && cd go-demo-app-ops
git reset --hard 57f2c76
git push -f
cd ~/workspace-demo
