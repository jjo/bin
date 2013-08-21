#!/bin/sh
# Q&D "rsync my Biblio-jjo" to android script
#
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
# * ~/.ssh/dropbear-android.key <- generated with:
#   dropbearkey -f ~/.ssh/dropbear-android.key
# * rsync <- install:
#   https://play.google.com/store/apps/details?id=eu.kowalczuk.rsync4android
#
RSYNC_OPTS="-vloDtrCz --modify-window=3600"
SSH_KEY_F=dropbear-android.key
SSH_KEY=~/.ssh/$SSH_KEY_F
SDCARD_DIR=/sdcard/download
LOCAL_DIR=/home/jjo/Dropbox/jjo/Biblio-jjo
REMHOST=192.168.100.11
REMUSER=jjo

do_runlocal() {
    ## This runs at the android
    PATH="$PATH:/data/data/eu.kowalczuk.rsync4android/files"
    export HOME=/sdcard
    uname -a
    cd /sdcard
    set -x
    rsync $RSYNC_OPTS --delete -e "ssh -i $SDCARD_DIR/$SSH_KEY_F" \
	    $REMUSER@$REMHOST:$LOCAL_DIR $SDCARD_DIR
}
do_run() {
    adb shell sh $SDCARD_DIR/jjo-android-rsync.sh runlocal
}
do_du() {
    du -s $LOCAL_DIR
    adb shell du -s $SDCARD_DIR/Biblio-jjo
}
case "$1" in
    run)
      do_run;;
    runlocal)
      do_runlocal;;
    push)
      adb push $0 $SDCARD_DIR;;
    pushkey)
      adb push $SSH_KEY $SDCARD_DIR/$SSH_KEY_F;;
    sshconf)
      echo "command="rsync --server  --sender -vloDtrCz . $LOCAL_DIR" ssh-rsa $(dropbearkey -y -f $SSH_KEY|egrep ^ssh-)";;
    du)
      do_du;;
esac
