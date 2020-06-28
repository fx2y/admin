#!/bin/bash
RESET_FONT="\033[0m"
BOLD="\033[1m"
GREEN="\033[0;92m"

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

echo -e "${GREEN}###### Sourcing credentials${RESET_FONT}"
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

echo -e "${GREEN}###### Validate that you are connected to a cluster${RESET_FONT}"
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
if [[ $(kubectl get nodes -o jsonpath="${JSONPATH}" | grep "Ready=True") == "" ]]; then
  echo -e "${GREEN}Please log into a Kubernetes cluster and try again"
  kill -INT $$
else
  echo -e "Using cluster:\n $(kubectl cluster-info)"
fi

echo -e "${GREEN}###### Delete/recreate dev and prod namespaces${RESET_FONT}"
kubectl delete ns dev
kubectl delete ns prod
kubectl create ns dev
kubectl create ns prod

echo -e "${GREEN}###### Delete/reinstall Tekton${RESET_FONT}"
kubectl delete ns tekton-pipelines
echo -e "${GREEN}###### Tekton Hack"
curl -s https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.13.2/release.yaml | sed '$ d' | yq d -d '*' - 'metadata.labels.[app.kubernetes.io/part-of]' | kubectl apply -f -
echo -e "${GREEN}###### Sleepy time"
sleep 5
echo -e "${GREEN}###### Tekton Fo Real Nao${RESET_FONT}"
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.13.2/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kns tekton-pipelines
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/git/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/lint.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/tests.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/kaniko/kaniko.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/buildpacks/buildpacks-v3.yaml

echo -e "${GREEN}###### Delete/reinstall ArgoCD${RESET_FONT}"
kubectl delete ns argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
yq m <(kubectl get cm argocd-cm -o yaml -n argocd) <(cat << EOF
data:
  kustomize.buildOptions: --load_restrictor none
EOF
) | kubectl apply -f -

echo -e "${GREEN}###### Delete/reinstall kpack${RESET_FONT}"
kubectl delete ns kpack
kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.0.9/release-0.0.9.yaml


echo -e "${GREEN}###### Install the Docker Hub secret${RESET_FONT}"
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

echo -e "${GREEN}###### Install the GitHub token secret${RESET_FONT}"
kubectl create secret generic github-token --from-literal=GITHUB_TOKEN=${GITHUB_TOKEN} -n tekton-pipelines

echo -e "${GREEN}###### Fixing build-bot permissions${RESET_FONT}"
kubectl create clusterrolebinding build-bot --clusterrole=cluster-admin --serviceaccount=tekton-pipelines:build-bot
