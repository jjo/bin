#!/bin/bash -x
case ${XDG_SESSION_TYPE:?} in
    wayland|x11)
        sudo chown $USER /dev/uinput
        printf "%s\n" ydotoold syngestures |xargs -tI@ -P0 bash -c @
        exit $?
        ;;
esac
