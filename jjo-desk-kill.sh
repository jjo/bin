#!/bin/bash
# "kill" desktop apps, sp to save battery, e.g. $0 STOP / $0 CONT
signal=${1:?Missing signal e.g.: STOP|CONT}
exec pkill -e -f -${signal} '(telegram-desktop|brave|chrome|slack|keybase|zoom|dropbox)'
