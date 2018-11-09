#!/bin/sh
node=${1}
if [ -n "${node}" ]; then
    shift
    nodeName=$(kubectl get node ${node} -o template --template='{{index .metadata.labels "kubernetes.io/hostname"}}') || exit 1
    nodeSelector='"nodeSelector": { "kubernetes.io/hostname": "'${nodeName:?}'" },'
    podName=${USER+${USER}-}sudo-${node}
else
    nodeSelector=""
    podName=${USER+${USER}-}sudo
fi
set -x
kubectl run ${podName:?} --restart=Never -it \
    --image overriden --overrides '
{
  "spec": {
    "hostPID": true,
    "hostNetwork": true,
    '"${nodeSelector?}"'
    "tolerations": [{
        "effect": "NoSchedule",
        "key": "node-role.kubernetes.io/master"
    }],
    "containers": [
      {
        "name": "alpine",
        "image": "alpine:3.7",
        "command": ["nsenter", "--mount=/proc/1/ns/mnt", "--", "/bin/bash"],
        "stdin": true,
        "tty": true,
        "resources": {"requests": {"cpu": "10m"}},
        "securityContext": {
          "privileged": true
        }
      }
    ]
  }
}' --rm --attach "$@"
