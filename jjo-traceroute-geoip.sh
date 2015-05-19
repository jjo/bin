#!/bin/sh
traceroute "${@:?missing traceroute args}" |awk '($2~/\./){"geoiplookup "$2 |getline geo;$0=sprintf("%-64s %s", $0, geo)}{print}'
