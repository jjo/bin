#!/bin/bash
# Print oathtool commands to stdout that do produce same OTPs
# as Google Authenticator App, by steal^Wusing its saved keys.
#
# Last tested against rooted Nexus 5, Lollipop --jjo, 2016-07-12
#
# Requires rooted android, and sqlite3 cmd at the phone:
#
# Howto:
#   http://stackoverflow.com/questions/7877891/sqlite3-not-found
# sqlite3 as of Jun/2015:
#   http://forum.xda-developers.com/showthread.php?t=2730422
#
# Example (obfuscated) output:
# oathtool --totp -b XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 	# Google:[...]@[...]
# oathtool -c 7   -b XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 	# UbuntuSSO/[...]@[...]
# oathtool --totp -b XXXXXXXXXXXXXXXXXXXXXXXXXX 	# Dropbox:[...]@[...]
#
# You may want to see exactly the same OTPs that your phone is showing ;):
#   ./jjo-android-google-auth-to-oathtool.sh | sh -v
# You may want to backup these keys:
#   ./jjo-android-google-auth-to-oathtool.sh | gpg -e -o google-auth-oathtool.bak.gpg
#
# ... and/or backup the output from:
# adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases .dump

adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases \
   '"select issuer, email, secret, counter, type from accounts"' | \
   awk -v FS='|' ' {
     x=$5? sprintf ("-c %d", $4) : sprintf ("--totp");
     printf ("oathtool %6s -b %s \t# [%s] %s\n", x, $3, $1, $2)
   }'
