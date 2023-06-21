#!/bin/bash
# Fake the app to be running in Ubuntu
# e.g.  jjo-run-ubuntu.sh zoom
UBUNTU_RELEASE=ubuntu:22.04 # docker image

for f in etc/lsb-release etc/os-release; do
    test -f ~/${f}.ubuntu || docker run "${UBUNTU_RELEASE}" cat /${f} | install -D -m 644 /dev/stdin ~/${f}.ubuntu
done
exec bwrap --dev-bind / / --ro-bind /run /run --ro-bind /opt /opt --ro-bind ~/etc/lsb-release.ubuntu /etc/lsb-release --ro-bind ~/etc/os-release.ubuntu /etc/os-release "${@:?missing CLI}"
