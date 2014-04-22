#!/bin/bash
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# show topN processes sorted by OOM killer like-ability
egrep . /proc/[0-9]*/*oom_score|sort -n -k2 -t:|tail -10|sed -nr 's%/proc/([0-9]+)/.*:([0-9]+)%echo "\2: $(ps --no-headers -opid,pcpu,rss,vsz,args:80,etime \1)"%p'|bash
