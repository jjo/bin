#!/usr/bin/env python3
# Report some crytocurrencies value by BTC, USD
import requests
from jinja2 import Template

URL = "https://poloniex.com/public"
COINS = "BTC ZEC ETH DASH OMNI XMR NOTE DGB DOGE".split()

r = requests.get(URL, params={'command': 'returnTicker'})
tickers = r.json()

for coin in COINS:
    usd_coin = "USDT_" + coin
    if usd_coin not in tickers.keys():
        tickers[usd_coin] = {
            "last": "{:.8f}".format(
                float(tickers["BTC_" + coin]["last"])
                * float(tickers["USDT_BTC"]["last"])
            ),
            "percentChange": tickers["BTC_" + coin]["percentChange"],
        }


coin_conv = [[{'name': t + x,
               'last': tickers[t + x]['last'],
               'pct': tickers[t + x].get('percentChange'),
               }
              for x in COINS if t != x + "_"] for t in ('USDT_', 'BTC_')]

template = Template(
"""{% for c in coins -%}
{{c.name.ljust(16)}} {{c.last.rjust(20)}} {{c.pct.rjust(16)}}
{% endfor -%}""") # noqa

for coins in coin_conv:
    print(template.render(coins=sorted(coins, key=lambda x: -float(x['last']))),
          end='--\n')
