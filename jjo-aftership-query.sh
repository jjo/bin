#!/bin/bash
. ~/etc/aftership.key
: ${AFTERSHIP_KEY:?}
FILTER='select(.tag!="Delivered")|'
MANY=""
[[ $1 == -a ]] && FILTER=""
[[ $1 == -1 ]] && MANY=-1
curl -sH "aftership-api-key: ${AFTERSHIP_KEY:?}" https://api.aftership.com/v4/trackings|\
jq -r '.data.trackings[]|'"${FILTER}"'("==[ " + .tracking_number + " ][ " + .tag + " ] " + .title),(.checkpoints['"${MANY}"']|("  " + .checkpoint_time + " :  " + .message))'
