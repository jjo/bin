#!/bin/bash -x
find ~/.thunderbird -name '*.sqlite' -print0|xargs -tI@ --null time sqlite3 @ "VACUUM;"
