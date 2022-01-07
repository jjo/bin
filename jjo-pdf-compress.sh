#!/bin/bash
IN="${1:?missing input file}"
OUT="${2:?missing input file}"
set -x
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages -dCompressFonts=true -r75 -sOutputFile="${OUT}" "${IN}"
