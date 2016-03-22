#!/bin/bash
# jjo-lxc-launch.sh: launch LXD/lxc priviledged container with:
#                    - $HOME bindmount'd
#                    - 1st user == myself
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
# Keywords: lxc, lxd, idmap, bind mount
#
help() {
	(
	echo "Usage: ${0##*/} imagename name"
	echo ""
	echo "# Sync images:"
	echo "  lxc image copy ubuntu:14.04 local: --alias ubuntu-trusty"
	echo "  lxc image copy ubuntu:16.04 local: --alias ubuntu-xenial"
	echo "# Launch:"
	echo "  ${0##*/} ubuntu-xenial $USER-xenial-01"
	echo ""
	) >&2
}

image=${1:?missing imagename. $(help)}
name=${2:?missing name. $(help)}

# Init privileged container, needed to have 1:1 idmapping
(set -x;lxc init $image $name -c security.nesting=true -c security.privileged=true)

# Create cloud-init userdata with my account, ssh keys in it
(
cat << EOF
#cloud-config
users:
  - name: $USER
    shell: /bin/bash
    uid: $(id -u)
    gid: $(id -g)
    sudo: ALL=(ALL) NOPASSWD:ALL
    #ssh-import-id: [$USER]
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_rsa.pub)

EOF
) | (set -x; lxc config set $name user.user-data -)

# Add $HOME bindmount
(set -x; lxc config device add $name homedir disk source=$HOME path=$HOME)

# Start it
(set -x;lxc start $name)
