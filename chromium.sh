#!/bin/bash -x
exec chromium-browser --enable-sync --enable-user-scripts --enable-extensions --enable-plugins --new-new-tab-page "$@"
#exec google-chrome --enable-user-scripts --enable-extensions --new-new-tab-page "$@"
