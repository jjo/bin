#!/bin/sh
mplayer -prefer-ipv4 -cache 512 "$@" -playlist http://www.radioparadise.com/musiclinks/rp_64aac.m3u
