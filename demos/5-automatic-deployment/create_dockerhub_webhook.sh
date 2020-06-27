#!/bin/bash

while [ $(kubectl get svc el-ops-dev-event-listener -n tekton-pipelines -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | wc -w) != 1 ] ; do echo "Waiting for event listener to expose external IP..." && sleep 5 ; done

http -h -v POST https://hub.docker.com/v2/repositories/andreasevers/go-sample-app/webhook_pipeline/ Authorization:"JWT ${DOCKERHUB_TOKEN}" <<EOF
{
	"name": "tekton",
	"webhooks": [
		{
			"name": "tekton",
			"hook_url": "http://$(kubectl get svc el-ops-dev-event-listener -n tekton-pipelines -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8080"
		}
	]
}
EOF

#{"name":"test","expect_final_callback":false,"webhooks":[{"name":"test","hook_url":"https://test.org/redirect"}],"registry":"registry-1.docker.io"}
