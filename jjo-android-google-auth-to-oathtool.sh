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
# You may want to backup these :)
#   ./jjo-android-google-auth-to-oathtool.sh | gpg -e -o google-auth-oathtool.bak.gpg
# ... and/or backup the output from:
# adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases .dump

adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases \
   "select email, secret, counter, type from accounts" | \
   awk -v FS='|' ' {
     printf ("oathtool")
     if ($4) printf (" -c %s   ", $3); else printf (" --totp ");
     printf ("-b %s \t# %s\n", $2, $1)
   }'
