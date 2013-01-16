#!/bin/bash
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3

# Shell only twitter scraping, to see the evolution of informal USD currency exchange,
# from @dolarblue twitter account.
curl -s 'https://api.twitter.com/1/statuses/user_timeline.json?include_entities=true&include_rts=true&screen_name=dolarblue&count=40'|egrep -o '([{]"created_at|text)":"[^"]+"'| sed -nr 's/.*":"(.*[$])?(.+)"/\2/p' |xargs -l2
