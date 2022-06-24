#!/bin/bash
set -e



/scripts/get-kubeconfig.sh ${CLUSTER}
/scripts/bootstrap-helm.sh

source /scripts/common.sh

helm repo update
# helmfile --environment $HELM_ENV -f ./helmfile.pre.d sync

wait_pod_ready cert-manager-webhook cert-manager

/scripts/deploy.sh -c ${CLUSTER}
