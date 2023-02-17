#!/bin/bash
# Fake the app to be running in Ubuntu
# e.g.  jjo-run-ubuntu.sh zoom
exec bwrap --dev-bind / / --ro-bind /run /run --ro-bind /opt /opt --ro-bind ~/etc/lsb-release.ubuntu /etc/lsb-release --ro-bind ~/etc/os-release.ubuntu /etc/os-release "${@:?missing CLI}"
