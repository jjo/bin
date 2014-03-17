#!/bin/bash
# Print oathtool commands to stdout that do produce same OTPs
# as Google Authenticator App, by steal^Wusing its saved keys.
# Requires rooted android.
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
# ... and/or backup the output from:
# adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases .dump

adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases \
   "select email, secret, counter, type from accounts" | \
   awk -v FS='|' ' {
     x=$4? sprintf (" -c %4d", $3) : sprintf (" --totp ");
     printf ("oathtool %s -b %s \t# %s\n", x, $2, $1)
   }'
