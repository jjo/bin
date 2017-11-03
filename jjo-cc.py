#!/usr/bin/env python3
# Report some crytocurrencies value by BTC, USD
import asyncio
import requests
from jinja2 import Template

# Q&D from several sources
POLONIEX_URL = "https://poloniex.com/public"
POLONIEX_COINS = "BTC BCH ZEC ETH DASH OMNI XMR NOTE DGB DOGE POT LSK".split()
HITBTC_URL = "https://api.hitbtc.com/api/1/public/%sBTC/ticker"
HITBTC_COINS = "TKN BTG".split()


def get_poloniex(coins):
    "Poloniex returns all tickers in a single call"
    assert isinstance(coins, list)
    r = requests.get(POLONIEX_URL, params={'command': 'returnTicker'})
    tickers = r.json()
    return tickers


def get_hitbtc(coin):
    "Hitbtc requires one call per ticker (driven by asyncio below)"
    assert isinstance(coin, str)
    entry = requests.get(HITBTC_URL % coin).json()
    ticker = {"BTC_" + coin: {
        "last": entry["last"],
        "percentChange": "{:.8f}".format(
            float(entry["last"]) / (float(entry["open"])) - 1)
    }}
    return ticker


async def fetch():
    loop = asyncio.get_event_loop()
    futures_poloniex = [
        loop.run_in_executor(None, get_poloniex, POLONIEX_COINS)]
    futures_hitbtc = [
        loop.run_in_executor(None, get_hitbtc, coin) for coin in HITBTC_COINS]
    futures = futures_poloniex + futures_hitbtc
    tickers = {}
    for response in await asyncio.gather(*futures):
        tickers.update(response)
    return tickers

loop = asyncio.get_event_loop()
tickers = loop.run_until_complete(fetch())

COINS = POLONIEX_COINS + HITBTC_COINS

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
