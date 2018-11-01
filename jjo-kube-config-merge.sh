#!/bin/bash
TO_ADD=${1:?missing config_file to add}

ls ${TO_ADD} >/dev/null || exit 1
DEF_CONFIG="${HOME}/.kube/config"
KUBECONFIG="${DEF_CONFIG}:${TO_ADD}" kubectl config view --flatten > ${DEF_CONFIG}.new && mv --backup=numbered ${DEF_CONFIG}{.new,}
