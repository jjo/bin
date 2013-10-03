#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#   


host="${@: -1}" ## last argument
[[ $TERM = screen ]] && echo -ne "\ek${host%%.[a-z]*[a-z]}\e\\" ## host without "domain"
if [ -n "$MOSH_GATE" ];then
	echo "Using MOSH_GATE: $MOSH_GATE"
	mosh -- $MOSH_GATE bash -ic "ssh $@"
else
	ssh -C "$@"
fi
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
