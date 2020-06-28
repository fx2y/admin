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

echo -e "${PURPLE}###### Clearing and setting up workspace-demo${RESET_FONT}"
cd ~/workspace-demo
rm -rf ~/workspace-demo/*

echo -e "${PURPLE}###### Cloning demorunner${RESET_FONT}"
git clone git@github.com:mgbrodi/demorunner.git ~/workspace-demo/demorunner

echo -e "${PURPLE}###### Setting up APP repo${RESET_FONT}"
git clone https://github.com/springone-tour-2020-cicd/go-demo-app.git && cd go-demo-app
cd ~/workspace-demo

echo -e "${PURPLE}###### Setting up OPS repo${RESET_FONT}"
git clone https://github.com/springone-tour-2020-cicd/go-demo-app-ops.git && cd go-demo-app-ops
cd ~/workspace-demo

echo -e "${PURPLE}###### Adding final ops files inside OPS repo${RESET_FONT}"
cp -r $ADMIN/demos/manifests/ ~/workspace-demo/go-demo-app-ops/

echo -e "${PURPLE}###### Setting up webhook scripts${RESET_FONT}"
cp ${ADMIN}/demos/3-workflow-automation/create_github_webhook.sh ~/create_github_webhook.sh
cp ${ADMIN}/demos/5-automatic-deployment/create_dockerhub_webhook.sh ~/create_dockerhub_webhook.sh
chmod +x ~/create_github_webhook.sh
chmod +x ~/create_dockerhub_webhook.sh
