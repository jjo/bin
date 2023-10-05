#!/bin/bash
# Simple tempo adjustment using ffmpeg (keeping pitch).
ratio=${1:?missing ratio, e.g.: 1.2}
inp_file=${2:?missing input file}
out_file=${3:?missing output file}
shift 3

ratio_inverse=$(bc -l <<<"1/$ratio")
set -x
exec ffmpeg -i "${inp_file}" -tune grain -filter:a "atempo=${ratio}" -vf  "setpts=${ratio_inverse}*PTS" "${out_file}" "${@}"
