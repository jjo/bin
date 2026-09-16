#!/bin/bash
#
file=${1:?"Usage: $0 <markdown_file>"}

# Exported via Chrome extension:
# https://github.com/jatinkrmalik/LLMFeeder
# -> need to remove last `Source: ...' line
title=$(sed -rn '/^Source: /s/[^[]+.([^]]+).*/\1/p' "$file")
author=$(echo "${title}" | sed -rn 's/.+ by (.+)/\1/p')
test -n "${author}" && title=$(echo "$title" | sed -rn 's/(.+) by .+/\1/p')
test -z "${title}" && title=$(basename "${file}")
set -e
sed '/^Source:/d' "${file}" | pandoc -M title="${title}" -M author="${author}" -f markdown -t epub3 -o "${file%.md}.epub"
command -v kepubify >/dev/null 2>&1 && {
  kepubify "${file%.md}.epub"
  mv "${file%.md}_converted.kepub.epub" "${file%.md}.epub"
}
echo "Saved to: ${file%.md}.epub"
