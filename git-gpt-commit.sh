#!/bin/bash

. ~/etc/openai.env
. ~/go/src/github.com/markuswt/gpt-commit/.venv/bin/activate
~/go/src/github.com/markuswt/gpt-commit/gpt-commit.py "$@"

