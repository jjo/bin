#!/bin/bash -v
elinks -no-numbering -no-references http://internetpulse.net/?Metric=PL |egrep --color=no -e 'Dest|Gener' -e "NTT.*XO" -e " 0 .* 0  "
