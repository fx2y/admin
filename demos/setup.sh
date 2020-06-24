# This script assumes you are logged into a cluster dedicated exclusively to this demo
# It will delete and reinstall the namespaces and tools required:
#   namespace: dev
#   namespace: prod
#   tekton
#   argocd
#   kpack

DEMO_HOME="${PWD}"
DEMO_TEMP=temp/demos/cicd
rm -rf "${DEMO_TEMP}"
mkdir -p "${DEMO_TEMP}"
cd "${DEMO_TEMP}"

DEMO_DEV_NS=dev
DEMO_PROD_NS=prod

# You must be connected to a cluster
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
if [[ $(kubectl get nodes -o jsonpath="${JSONPATH}" | grep "Ready=True") == "" ]]; then
  echo "Please log into a Kubernetes cluster and try again"
  kill -INT $$
else
  echo -e "Using cluster:\n $(kubectl cluster-info)"
fi

# Deleting/recreate dev and prod namespaces
kubectl delete ns "${DEMO_DEV_NS}"
kubectl delete ns "${DEMO_PROD_NS}"
kubectl create ns "${DEMO_DEV_NS}"
kubectl create ns "${DEMO_PROD_NS}"

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
kubectl delete ns
kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.0.9/release-0.0.9.yaml



