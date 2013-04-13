#!/bin/bash -x
exec mplayer "$@" -playlist http://streams.movemedia.eu:8330/listen.pls
