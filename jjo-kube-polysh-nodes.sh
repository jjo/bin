#!/bin/bash
NODES=$(kubectl get node -ojsonpath={.items[*].status.addresses[0].address})
set -x
~/polysh/run.py --user ubuntu ${NODES}
