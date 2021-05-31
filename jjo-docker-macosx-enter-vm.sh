#!/bin/bash
# docker run -it --rm --privileged --pid=host justincormack/nsenter1 "$@"
RUN_OPTS="-i --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i"
case "$1" in
    --setup)
        exec docker run ${RUN_OPTS} <<-EOF
            set -x
            hostname
            mount -oremount,rw /
            # docker / binaries CLI setup
            test -L /lib64 || ln -s /containers/services/docker/rootfs/lib64 /lib64
            test -L /lib/x86_64-linux-gnu || ln -s /containers/services/docker/rootfs/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu
            grep DOCKER_HOST /etc/profile || echo 'export DOCKER_HOST=unix:///containers/services/docker/rootfs/var/run/docker.sock' >> /etc/profile
            test -L /usr/bin/docker || ln -s /containers/services/docker/rootfs/usr/bin/docker /usr/bin/docker
            # apk setup
            mkdir -p /var/cache/apk /var/lib/apk /usr/share/apk /etc/apk/protected_paths.d /etc/apk/keys /etc/apk/commit_hooks.d /etc/apk/repositories.d /etc/apk/cache
            apk update
EOF
        ;;
    --fix-ssh)
        (set -x; exec docker run ${RUN_OPTS} sh -c "chown -v $(id -u):$(id -g) /run/host-services/ssh-auth.sock"); RC=$?
        echo "# HINT: verify/ run docker with ssh-agent auth with:"
        echo 'docker run -it -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" -u $(id -u):$(id -g) kroniak/ssh-client ssh-add -l'
        exit $RC
        ;;
    *);;
esac
exec docker run -t ${RUN_OPTS} "$@"
