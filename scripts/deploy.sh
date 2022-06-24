#!/bin/bash

set -e
/scripts/get-kubeconfig.sh ${CLUSTER}
/scripts/bootstrap-helm.sh

source /scripts/common.sh

helm repo update
/scripts/deploy.sh -c ${CLUSTER}
