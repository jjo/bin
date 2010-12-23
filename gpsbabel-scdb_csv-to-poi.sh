#!/bin/bash 
set -e
export LC_ALL=de ## for sed
for f in "${@:?missing csv}";do
  bn="${f%.csv}"
  of="$bn.poi"
  gpsbabel -i unicsv \
    -f <(
      echo Longitude,Latitude,Description; 
      sed -r -e 's/"([^"]+),([^"]+)"/"\1;\2"/' -e 's/"([^"]+)","([^"]+)"$/"\2 \1"/' $f
      #sed -r 's/"([^"]+),([^"]+)"/"\1;\2"/' $f
    ) \
    -o tomtom -F out/$bn.ov2
    #-o garmin_gpi,category="$bn",bitmap=$bn.bmp -F out/$bn.gpi
done
