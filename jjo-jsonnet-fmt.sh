#!/bin/sh
FMT="--indent 2 --string-style d --comment-style s --no-pad-arrays --pad-objects --pretty-field-names"
jsonnetfmt $FMT "$@" && echo OK || echo FAIL
