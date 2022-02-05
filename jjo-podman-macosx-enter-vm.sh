#!/bin/bash
## Then: sshfs -o uid=1000 -p 10000 jjo@127.0.0.1:/Users /Users
set -x
exec ssh -A -i ~/.ssh/podman-machine-default -R 10000:$(hostname):22 -p $(podman system connection list | gsed -nE 's,.*localhost:([0-9]+)/run/user.*,\1,p') core@localhost "${@}"
