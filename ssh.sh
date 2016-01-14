#!/bin/bash
# update screen's title="hostname", from: ssh.sh "hostname".domain.foo
#
# very useful addition to ~/.bashrc:
#    complete -F _ssh ssh.sh
#

SSH_OPTS='-o ServerAliveInterval=300 -C'
host="${@: -1}" ## last argument

# remove some common prefixes:
host=${host#maas.}
# remove everything after 1st dot (~domain)
host=${host%%.[a-z]*[a-z]}

[[ $TERM = screen ]] && echo -ne "\ek${host}\e\\"
if [ -n "$MOSH_GATE" -a "$host" != "$MOSH_GATE" ];then
	echo "Using MOSH_GATE: $MOSH_GATE"
	# -A requires mosh built from
	# https://github.com/rinne/mosh/tree/ssh-agent-forwarding
	mosh -A -- $MOSH_GATE bash -ic "ssh ${SSH_OPTS} $@"
else
	ssh ${SSH_OPTS} "$@"
fi
[[ $TERM = screen ]] && echo -ne "\ek${SHELL##*/}\e\\"
