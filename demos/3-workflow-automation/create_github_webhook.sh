#!/bin/bash

while [ $(kubectl get svc el-build-event-listener -n tekton-pipelines -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | wc -w) != 1 ] ; do echo "Waiting for event listener to expose external IP..." && sleep 5 ; done

hub api -X POST -H "Authorization: token ${GITHUB_TOKEN}" /repos/andreasevers/go-sample-app/hooks --input - <<EOF
{
  "name": "web",
  "active": true,
  "events": [
    "push",
    "pull_request"
  ],
  "config": {
    "url": "http://$(kubectl get svc el-build-event-listener -n tekton-pipelines -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8080",
    "content_type": "json",
    "insecure_ssl": "0"
  }
}
EOF
