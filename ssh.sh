#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#   

host="${@: -1}" ## last argument
echo -ne "\ek${host%%.*}\e\\" ## host without "domain"
ssh "$@"
echo -ne "\ek${SHELL##*/}\e\\"
