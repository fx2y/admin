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

source aliases.sh

PATH=~/workspace/demorunner/bin:$PATH

GITLAB_NS="${GITLAB_NS:-ciberkleid}"
GITHUB_NS="${GITHUB_NS:-ciberkleid}"
GITHUB_USER=${GITHUB_USER:-ciberkleid}
IMG_NS="${IMG_NS:-ciberkleid}"
GITHUB_TOKEN=${GITHUB_TOKEN}
DOCKERHUB_USER=${DOCKERHUB_USER:-ciberkleid}
DOCKERHUB_PWD=${DOCKERHUB_PWD}

# Validate that you are connected to a cluster
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
if [[ $(kubectl get nodes -o jsonpath="${JSONPATH}" | grep "Ready=True") == "" ]]; then
  echo "Please log into a Kubernetes cluster and try again"
  kill -INT $$
else
  echo -e "Using cluster:\n $(kubectl cluster-info)"
fi

# Delete/recreate dev and prod namespaces
kubectl delete ns dev
kubectl delete ns prod
kubectl create ns dev
kubectl create ns prod

# Delete/reinstall Tekton
kubectl delete ns tekton-pipelines
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.13.2/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/git/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/lint.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/golang/tests.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/kaniko/kaniko.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/v1beta1/buildpacks/buildpacks-v3.yaml

# Delete/reinstall ArgoCD
kubectl delete ns argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
yq m <(kubectl get cm argocd-cm -o yaml -n argocd) <(cat << EOF
data:
  kustomize.buildOptions: --load_restrictor none
EOF
) | kubectl apply -f -

# Delete/reinstall kpack
kubectl delete ns kpack
kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.0.9/release-0.0.9.yaml

# Get the demo-files
git clone git@github.com:springone-tour-2020-cicd/demo-files.git
DEMO=${PWD}/demo-files

# Install the Docker Hub secret
docker login -u $IMG_NS

touch config.json
storetype=$(jq -r .credsStore < ~/.docker/config.json)
(
    echo '{'
    echo '    "auths": {'
    for registry in $(docker-credential-$storetype list | jq -r 'to_entries[] | .key' | grep index.docker.io); do
        if [ ! -z $FIRST ]; then
            echo '        },'
        fi
        FIRST=true
        credential=$(echo $registry | docker-credential-$storetype get | jq -jr '"\(.Username):\(.Secret)"' | base64)
        echo '        "'$registry'": {'
        echo '            "auth": "'$credential'"'
    done
    echo '        }'
    echo '    }'
    echo '}'
) > config.json
kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson -n tekton-pipelines
kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson -n default
rm -f config.json

# get token to be able to talk to Docker Hub
DOCKERHUB_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USER}'", "password": "'${DOCKERHUB_PWD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# Install the GitHub token secret
kubectl create secret generic github-token --from-literal=GITHUB_TOKEN=${GITHUB_TOKEN} -n tekton-pipelines

# Make the webhook scripts executable
mv ~/repos/springonetour2020/admin/demos/3-workflow-automation/create_github_webhook.sh ${HOME}/create_github_webhook.sh
mv ~/repos/springonetour2020/admin/demos/5-automatic-deployment/create_dockerhub_webhook.sh ${HOME}/create_dockerhub_webhook.sh
chmod +x ${HOME}/create_github_webhook.sh
chmod +x ${HOME}/create_dockerhub_webhook.sh
