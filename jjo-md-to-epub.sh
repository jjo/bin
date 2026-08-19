#!/bin/bash
#
file=${1:?"Usage: $0 <markdown_file>"}

# Exported via Chrome extension:
# https://github.com/jatinkrmalik/LLMFeeder
# -> need to remove last `Source: ...' line
title=$(sed -rn '/^Source: /s/[^[]+.([^]]+).*/\1/p' "$file")
test -z "$title" && title=$(basename "$file")
sed '/^Source:/d' "$file" | pandoc --metadata title="$title" -f markdown -t epub3 -o "${file%.md}.epub"
echo "Saved to: ${file%.md}.epub"
