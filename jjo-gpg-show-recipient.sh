#!/bin/sh
gpg --list-only --no-default-keyring --secret-keyring /dev/null "${@}"
