#!/bin/bash
sed -i '1 s/^\xef\xbb\xbf//' "$@"
