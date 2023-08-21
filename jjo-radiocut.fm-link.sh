#!/bin/bash
hour="${1:-$(date '+%H/%M')}"
day="${2:-$(date '+%Y/%m/%d')}"

set -x
open "https://radiocut.fm/radiostation/mdzradio/listen/${day}/${hour}/00/"
