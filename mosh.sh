#!/bin/bash
# update screen's title="hostname", from: mosh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh mosh.sh
#   

host="${@: -1}" ## last argument
[[ $TERM = screen ]] && echo -ne "\ek${host%%.[a-z]*[a-z]}\e\\" ## host without "domain"
mosh "$@"
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
