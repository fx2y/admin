#!/bin/bash
RESET_FONT="\033[0m"
BOLD="\033[1m"
YELLOW="\033[38;5;11m"
BLUE="\033[0;34m"
RED="\033[0;31m"
WHITE="\033[38;5;15m"

# This script assumes you are logged into a cluster dedicated exclusively to this demo
# It will delete and reinstall the namespaces and tools required:
#   namespace: dev
#   namespace: prod
#   tekton
#   argocd
#   kpack


# You also need the following tools installed locally:
# tkn cli
# kustomize cli
# argocd cli
# jq
# base64
# yq (mikefarah)
# hub cli
# pack cli
# logs cli

source ${ADMIN}/demos/aliases.sh

cd ~/workspace-demo
rm -rf ~/workspace-demo/*
git clone git@github.com:mgbrodi/demorunner.git ~/workspace-demo/demorunner
PATH=~/workspace-demo/demorunner:$PATH

GITLAB_NS="${GITLAB_NS:-ciberkleid}"
GITHUB_NS="${GITHUB_NS:-ciberkleid}"
GITHUB_USER=${GITHUB_USER:-ciberkleid}
IMG_NS="${IMG_NS:-ciberkleid}"
GITHUB_TOKEN=${GITHUB_TOKEN}
DOCKERHUB_PWD=${DOCKERHUB_PWD}
DOCKERHUB_USER=${DOCKERHUB_USER:-ciberkleid}

echo -e "${YELLOW}###### Validate that you are connected to a cluster"
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
if [[ $(kubectl get nodes -o jsonpath="${JSONPATH}" | grep "Ready=True") == "" ]]; then
  echo -e "${YELLOW}Please log into a Kubernetes cluster and try again"
  kill -INT $$
else
  echo -e "Using cluster:\n $(kubectl cluster-info)"
fi

echo -e "${YELLOW}###### Delete/recreate dev and prod namespaces"
kubectl delete ns dev
kubectl delete ns prod
kubectl create ns dev
kubectl create ns prod

echo -e "${YELLOW}###### Delete/reinstall Tekton"
kubectl delete ns tekton-pipelines
echo -e "${YELLOW}###### Tekton Hack"
curl -s https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.13.2/release.yaml | sed '$ d' | yq d -d '*' - 'metadata.labels.[app.kubernetes.io/part-of]' | kubectl apply -f -
echo -e "${YELLOW}###### Sleepy time"
sleep 5
echo -e "${YELLOW}###### Tekton Fo Real Nao"
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.13.2/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/git/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/lint.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/tests.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/kaniko/kaniko.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/buildpacks/buildpacks-v3.yaml

echo -e "${YELLOW}###### Delete/reinstall ArgoCD"
kubectl delete ns argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
yq m <(kubectl get cm argocd-cm -o yaml -n argocd) <(cat << EOF
data:
  kustomize.buildOptions: --load_restrictor none
EOF
) | kubectl apply -f -

echo -e "${YELLOW}###### Delete/reinstall kpack"
kubectl delete ns kpack
kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.0.9/release-0.0.9.yaml

echo -e "${YELLOW}###### Set the workspace correctly"
cd ~/workspace-demo

echo -e "${YELLOW}###### Get the demo-files"
git clone git@github.com:springone-tour-2020-cicd/demo-files.git
DEMO=${PWD}/demo-files

echo -e "${YELLOW}###### Install the Docker Hub secret"
docker login -u $IMG_NS

touch config.json
storetype=$(jq -r .credsStore < ~/.docker/config.json)
(
    echo -e '{'
    echo -e '    "auths": {'
    for registry in $(docker-credential-$storetype list | jq -r 'to_entries[] | .key' | grep index.docker.io); do
        if [ ! -z $FIRST ]; then
            echo -e '        },'
        fi
        FIRST=true
        credential=$(echo -e $registry | docker-credential-$storetype get | jq -jr '"\(.Username):\(.Secret)"' | base64)
        echo -e '        "'$registry'": {'
        echo -e '            "auth": "'$credential'"'
    done
    echo -e '        }'
    echo -e '    }'
    echo -e '}'
) > config.json
kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson -n tekton-pipelines
kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson -n default
rm -f config.json

echo -e "${YELLOW}###### Get token to be able to talk to Docker Hub"
DOCKERHUB_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USER}'", "password": "'${DOCKERHUB_PWD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

echo -e "${YELLOW}###### Install the GitHub token secret"
kubectl create secret generic github-token --from-literal=GITHUB_TOKEN=${GITHUB_TOKEN} -n tekton-pipelines

echo -e "${YELLOW}###### Make the webhook scripts executable"
cp ${ADMIN}/demos/3-workflow-automation/create_github_webhook.sh ${HOME}/create_github_webhook.sh
cp ${ADMIN}/demos/5-automatic-deployment/create_dockerhub_webhook.sh ${HOME}/create_dockerhub_webhook.sh
chmod +x ~/create_github_webhook.sh
chmod +x ~/create_dockerhub_webhook.sh

