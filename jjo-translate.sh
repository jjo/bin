#!/bin/bash
# avail services
#: ${S:=www.freetranslation.com}
: ${S:=translate.google.com}
: ${L:=en-es}
set -x
#/usr/local/bin/tw www.freetranslation.com.en-es
/usr/local/bin/tw $S.$L "$*"
