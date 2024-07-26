#!/bin/bash

ansi2html "$@" | sed -E \
    -e '/<!DOCTYPE/d' \
    -e '/<style.*>/,/<.style>/d' \
    -e 's,<html>,<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">,' \
    -e 's,<body>,<foreignObject width="100" height="100"><div xmlns="http://www.w3.org/1999/xhtml">,' \
    -e 's,</body>,</div></foreignObject>,' \
    -e 's,</html>,</svg>,' \
    -e '/<\/?head>/d'
