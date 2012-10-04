#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#   

host="${@: -1}" ## last argument
[[ $TERM = screen ]] && echo -ne "\ek${host%%.[a-z]*[a-z]}\e\\" ## host without "domain"
ssh "$@"
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
