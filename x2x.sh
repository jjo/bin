#!/bin/bash
#
# Copyright 2008 Google Inc. All Rights Reserved.
# Author: jjo@google.com (JuanJo Ciarlante)
WHERE=${1:-west}
if [  -z "$SSH_CONNECTION" -o -z "$DISPLAY" ];then
    echo "Intended to be used from: ssh -X ..."
    exit 2
fi
set -x
#echo "Dont miss: \"xhost +local:\""
echo "Dont miss: \"xhost +SI:localuser:$USER\""
exec x2x -from :0 -$WHERE
