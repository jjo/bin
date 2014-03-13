#!/bin/bash
# Print oathtool commands to stdout that do produce same OTPs
# as Google Authenticator App - requires rooted android
adb shell su root sqlite3 /data/data/com.google.android.apps.authenticator2/databases/databases \
   "select email, secret, counter, type from accounts" | \
   awk -v FS='|' ' {
     printf ("oathtool")
     if ($4) printf (" -c %s   ", $3); else printf (" --totp ");
     printf ("-b %s \t# %s\n", $2, $1)
   }'
