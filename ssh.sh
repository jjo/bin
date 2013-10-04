#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#   


host="${@: -1}" ## last argument
[[ $TERM = screen ]] && echo -ne "\ek${host%%.[a-z]*[a-z]}\e\\" ## host without "domain"
if [ -n "$MOSH_GATE" -a "$host" != "$MOSH_GATE" ];then
	echo "Using MOSH_GATE: $MOSH_GATE"
	# -A requires mosh built from
	# https://github.com/rinne/mosh/tree/ssh-agent-forwarding
	mosh -A -- $MOSH_GATE bash -ic "ssh $@"
else
	ssh -C "$@"
fi
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
