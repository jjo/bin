#!/bin/bash
set -xeu
markdown ${1:?missing file.md} | htmldoc --charset  utf-8 --cont --footer ..1 --headfootsize 8.0 --linkcolor blue --linkstyle plain --format pdf14 - --outfile ${2:?missing file.pdf}
