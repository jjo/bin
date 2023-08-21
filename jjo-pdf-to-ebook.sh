#!/bin/bash
infile=${1:?missing infile.pdf}
outfile=${2:?missing outfile.pdf}
test -f "${outfile:?}" && echo "ERROR: ${outfile} already exists" && exit 1
set -x
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${outfile:?}.tmp" "${infile:?}" && mv "${outfile}.tmp" "${outfile}" || rm -f "${outfile}.tmp"
