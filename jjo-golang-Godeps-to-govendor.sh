#!/bin/bash -x
godeps_file=${1:-./Godeps}
shift
xargs_x=${*:- -P1} # govendor doesn't like parallelism too much :/
sed -nr 's/ /@/p' ${godeps_file} | xargs ${xargs_x} -tl1 govendor fetch


