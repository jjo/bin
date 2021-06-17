#!/bin/bash
# Parse foo-A-B-C-D-bar addresses to A.B.C.D
# Using last arg
typeset -i argc=${#}
eval host=\${${argc}}
host=$(echo ${host}|sed -r 's/[^0-9]+([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+).*/\1.\2.\3.\4/')
set -x
exec ssh ${@:1:$((argc-1))} -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${host}
