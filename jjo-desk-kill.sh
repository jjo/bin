#!/bin/bash
# "kill" desktop apps, sp to save battery, e.g. $0 STOP / $0 CONT
signal=${1:?Missing signal e.g.: STOP|CONT}
shift
PATT='telegram-desktop|brave|chrome|slack|keybase|zoom|dropbox'
remove=""
for i in "$@"; do
    case "$i" in
        -*) remove="${i#-}" ;;
        +*) add="${i#+}" ;;
    esac
    test -n "$remove" && PATT="${PATT//${remove}/}"
    test -n "$add" && PATT="${PATT}|${add}"
    PATT="${PATT//||/|}"
done
cmd="pkill -e -f -${signal} '(${PATT})'"
read -p "Ok (Ctrl-C to cancel)?  ->  ${cmd}" -n 1 -r
set -x
bash -c "${cmd}"|fmt -w80
