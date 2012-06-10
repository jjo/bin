#!/bin/bash -x
set -e
(
dpkg -l x2goserver && exit 0
#echo deb http://x2go.obviously-nice.de/deb/ lenny main | sudo tee /etc/apt/sources.list.d/x2go.list
#sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C509840B96F89133
sudo add-apt-repository ppa:x2go/stable
sudo apt-get update
sudo apt-get install x2goserver sqlite # core stuff
sudo apt-get install gnome-session x2gognomebindings # useful for gUI
)
(
echo sqlite | sudo tee /etc/x2go/sql
test -f /var/db/x2go/x2go_sessions && exit 0
cd /usr/lib/x2go/script && sudo ./x2gosqlite.sh
)
egrep -q localhost /etc/hosts || echo 127.0.0.1 localhost | sudo tee -a /etc/hosts && true
