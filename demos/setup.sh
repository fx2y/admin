# This script assumes you are logged into a cluster dedicated exclusively to this demo
# It will delete and reinstall the namespaces and tools required:
#   namespace: dev
#   namespace: prod
#   tekton
#   argocd
#   kpack

source aliases.sh

GITLAB_NS="${GITLAB_NS:-ciberkleid}"
IMG_NS="${IMG_NS:-ciberkleid}"

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

# Delete/reinstall kpack
kubectl delete ns kpack
kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.0.9/release-0.0.9.yaml



