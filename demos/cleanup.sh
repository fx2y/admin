#!/bin/bash
set -x
pkill kubectl

# Validate if anything's left
k get app,appproj,bldr,bld,clstbldr,img,sourceresolvers,pr,tr,pipelines,el,tb,tt,ctb,tasks,custmbldr,ccb,stacks,stores -A
k delete app,appproj,bldr,bld,clstbldr,img,sourceresolvers,pr,tr,pipelines,el,tb,tt,ctb,tasks,custmbldr,ccb,stacks,stores --all -A

k delete ns dev
k delete ns prod
k delete ns argocd
k delete ns kpack
k delete ns tekton-pipelines
k delete all --all -n default

# Namespace deletion stuck?
kubectl get namespace "tekton-pipelines" -o json | tr -d "\n" | sed "s/\"kubernetes\"//" | kubectl replace --raw /api/v1/namespaces/tekton-pipelines/finalize -f -

echo ">>>>>> 1. Remove Docker Hub webhook!!"
echo ">>>>>> 2. Remove Docker Hub repos!!"
echo ">>>>>> 3. Remove GitHub repos!!"
echo ">>>>>> 4. Remove Docker Daemon!!"

set +x
