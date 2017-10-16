#!/bin/bash
# jjo-pdf-compress.sh
#
in_file=${1:?missing input file}
out_file=${2:?missing output file}
mode=${3:-ebook}

if [ -f "${out_file}" ]; then
    echo "ERROR: '${out_file}' already exists."
    exit 255
fi

# -dPDFSETTINGS=/screen lower quality, smaller size.
# -dPDFSETTINGS=/ebook for better quality, but slightly larger pdfs.
# -dPDFSETTINGS=/prepress output similar to Acrobat Distiller "Prepress Optimized" setting
# -dPDFSETTINGS=/printer selects output similar to the Acrobat Distiller "Print Optimized" setting
# -dPDFSETTINGS=/default selects output intended to be useful across a wide variety of uses, possibly at the expense of a larger output file

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/${3} -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${out_file}" "${in_file}"
