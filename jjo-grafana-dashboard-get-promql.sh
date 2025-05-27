#!/bin/bash
DASHBOARD="${1:?missing /path/to/dashboard.json}"
jq -r '[..|.expr? // empty]|join("\n--\n")' "${DASHBOARD}"
