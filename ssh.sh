#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#

SSH_OPTS='-o ServerAliveInterval=300 -C'
host="${@: -1}" ## last argument
[[ $TERM = screen ]] && echo -ne "\ek${host%%.[a-z]*[a-z]}\e\\" ## host without "domain"
if [ -n "$MOSH_GATE" -a "$host" != "$MOSH_GATE" ];then
	echo "Using MOSH_GATE: $MOSH_GATE"
	# -A requires mosh built from
	# https://github.com/rinne/mosh/tree/ssh-agent-forwarding
	mosh -A -- $MOSH_GATE bash -ic "ssh ${SSH_OPTS} $@"
else
	ssh ${SSH_OPTS} "$@"
fi
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
