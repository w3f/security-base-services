#!/bin/bash

source /scripts/common.sh
source /scripts/bootstrap-helm.sh

run_tests() {
    echo Running tests...
    integration_test_sequence
}

integration_test_sequence(){
  echo Running intergration tests...
  wait_pod_ready metrics kube-system

}

teardown() {
  helmfile delete --purge
}

cert-manager() {
  helm repo update
  helmfile --environment $HELM_ENV -f ./helmfile.pre.d sync
  
  wait_pod_ready cert-manager-webhook cert-manager
}

main(){
    if [ -z "$KEEP_SECURTIY_BASE_SERVICES" ]; then
        trap teardown EXIT
    fi

    cert-manager

    source /scripts/build-helmfile.sh

    run_tests
}

main
