#!/bin/bash
dig -t TXT +short locations.publicdns.goog. @8.8.8.8|egrep -o '[1-9][^"]+' | sort -k2 | column -t
dig o-o.myaddr.l.google.com -t txt +short @8.8.8.8|paste -s

