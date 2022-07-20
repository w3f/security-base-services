#!/bin/bash

source /scripts/common.sh
source /scripts/bootstrap-helm.sh

run_tests() {
    echo Running tests...
    integration_test_sequence
}

integration_test_sequence(){
  echo Running intergration tests...
  wait_pod_ready cert-manager-webhook cert-manager
  wait_pod_ready vault-0 vault 3/3

}

pre_sync_check() {
  helm repo update
  helmfile --environment "$HELM_ENV" -f ./helmfile.pre.d sync

}

benchmark_crd_pool() {
  local CRD
  local CRD_VERSION

  echo Benchmarking CRD pool...
  # Generate kind cluster CRD pool
  # BASE_SERVICES_LAYER=$(kubectl get crds | cut -f 1 -d " " | grep -v ^NAME | grep -E -w -v "projectcalico.org|k8s.io|gke.io|.apiextensions|coreos.com")
  wait 
  for CRD_CONTEXT_VENDOR_DOMAIN in $(kubectl get crds | cut -f 1 -d " " | grep -v ^NAME |\
   grep -E -w -v "projectcalico.org|k8s.io|gke.io|.apiextensions|argoproj.io|google.com"); do

    echo "Gossipping on ${CRD_CONTEXT_VENDOR_DOMAIN} with kind cluster k8s api ..."
    CRD=$(kubectl get crds --all-namespaces | grep -E "^${CRD_CONTEXT_VENDOR_DOMAIN}" | cut -f 1 -d " " | xargs)
    wait 
    CRD_VERSION=$(kubectl describe crd "${CRD}" | grep -e "controller-gen.kubebuilder.io/version:" | cut -f 3 -d ":"| xargs)
    
    if [ -z "${CRD_VERSION}" ]; then
      # get app version referencing in the CRD
      CRD_VERSION=$(kubectl describe crd "${CRD}" | grep -e "app.kubernetes.io/version:*." | head -1 | cut -f2 -d "="| xargs)
    fi
    wait
    if [ -z "${CRD_VERSION}" ]; then
      # get CRD Package Manager as refrence
      CRD_VERSION=$(kubectl describe crd "${CRD}" |  grep -e "Manager::*." | head -1 | cut -f2 -d ":" | xargs)
    fi
    wait
    echo "export $CRD_CONTEXT_VENDOR_DOMAIN=$CRD_VERSION" >> /scripts/INTEGRATION.txt
    wait
  
  done
  
   diff -c /scripts/CLUSTER_CRD_MATRIX.txt /scripts/INTEGRATION.txt
}


main(){

    if [ -z "$KEEP_SECURTIY_BASE_SERVICES" ]; then
        trap teardown EXIT
    fi

    pre_sync_check
    source /scripts/build-helmfile.sh
    run_tests
    benchmark_crd_pool

    if [[ $? -ne 0 ]] ; then
      echo "CRD MISMATCH"
      echo "Warning: This PR Is altering cluster behaivior ..."
    else
      echo "controller-gen.kubebuilder.io/version: Static"
    fi

}

main
