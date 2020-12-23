#!/usr/bin/env python3
# Report some crytocurrencies value by BTC, USD
# Optionally report balance if passed a text file with lines in the form of:
# <site> <ticket> <amount>

import sys
import asyncio
import requests
from jinja2 import Template
import csv
from collections import defaultdict
import time

# Q&D from several sources
POLONIEX_URL = "https://poloniex.com/public"
POLONIEX_COINS = ("BTC ZEC ETH XMR "
                  "DOGE XRP BCHSV").split()
HITBTC_URL = "https://api.hitbtc.com/api/1/public/%sBTC/ticker"
HITBTC_COINS = "BTG TRX SBTC CRO".split()
BITTREX_URL = "https://bittrex.com/api/v1.1/public/getmarketsummaries"
BITTREX_COINS = "BCH".split()
BINANCE_URL = "https://api.binance.com/api/v1/ticker/24hr?symbol=%sBTC"
BINANCE_COINS = "XLM IOTA BNB EOS OMG LINK GO BEAM ADA BCHABC".split()

COINS = POLONIEX_COINS + HITBTC_COINS + BITTREX_COINS + BINANCE_COINS


def get_poloniex(coins):
    "Poloniex returns all tickers in a single call"
    assert isinstance(coins, list)
    r = requests.get(POLONIEX_URL, params={'command': 'returnTicker'})
    if (r.status_code != 200):
        raise Exception("'{}' failed with {}".format(r.url, r.status_code))
    tickers = r.json()
    return tickers


def get_hitbtc(coin):
    "Hitbtc requires one call per ticker (driven by asyncio below)"
    assert isinstance(coin, str)
    url = HITBTC_URL % coin
    r = requests.get(url)
    if (r.status_code != 200):
        raise Exception("'{}' failed with {}".format(r.url, r.status_code))
    entry=r.json()
    ticker = {"BTC_" + coin: {
        "last": entry["last"],
        "percentChange": "{:.8f}".format(
            float(entry["last"]) / (float(entry["open"])) - 1),
        "ref": "open",
    }}
    return ticker


def get_bitrex(coins):
    assert isinstance(coins, list)
    r = requests.get(BITTREX_URL)
    if (r.status_code != 200):
        raise Exception("'{}' failed with {}".format(r.url, r.status_code))
    tickers = {}
    for ticker in r.json()["result"]:
        market_name = ticker["MarketName"].replace("-", "_")
        if market_name.startswith("BTC_") and market_name[4:] in coins:
            tickers[market_name] = {
                "last": "{:.8f}".format(ticker["Last"]),
                "percentChange": "{:.8f}".format(
                    float(ticker["Last"]) / float(ticker["PrevDay"]) - 1)
            }
    return tickers


def get_binance(coin):
    "Binance requires one call per ticker (driven by asyncio below)"
    assert isinstance(coin, str)
    url = BINANCE_URL % coin
    r = requests.get(url)
    if (r.status_code != 200):
        raise Exception("'{}' failed with {}".format(r.url, r.status_code))
    entry=r.json()
    ticker = {"BTC_" + coin: {
        "last": entry["lastPrice"],
        "percentChange": "{:.8f}".format(
            float(entry["lastPrice"]) / (float(entry["openPrice"])) - 1),
        "ref": "open",
    }}
    return ticker


async def fetch():
    loop = asyncio.get_event_loop()
    futures = [
        loop.run_in_executor(None, get_poloniex, POLONIEX_COINS)
    ] + [
        loop.run_in_executor(None, get_hitbtc, coin) for coin in HITBTC_COINS
    ] + [
        loop.run_in_executor(None, get_bitrex, BITTREX_COINS)
    ] + [
        loop.run_in_executor(None, get_binance, coin) for coin in BINANCE_COINS
    ]

    tickers = {}
    for response in await asyncio.gather(*futures):
        tickers.update(response)
    return tickers


def get_balance(filename, tickers):
    """Q&D total from passed file in the form of:
       site  ticker  amount
    """
    d = defaultdict(dict)
    with open(filename, 'rt') as f:
        reader = csv.reader(f, delimiter='\t')
        for row in reader:
            if row != [] and row[0][0] != '#':
                d[row[0]].update({row[1]: row[2]})

    all_total = 0.0
    site_totals = []
    for site in d:
        site_total = 0
        site_total_txt = []
        for ticker, amount in sorted(d[site].items()):
            value = tickers['USDT_%s' % ticker.upper()]['last']
            site_total += float(
                tickers['USDT_%s' % ticker.upper()]['last']) * float(amount)
            site_total_txt.append('{}:{:.6f}'.format(ticker.upper(),
                                                     float(amount)))
        site_totals.append([site, "{:.2f}".format(site_total),
                            "  ".join(site_total_txt)])
        all_total += site_total
    site_totals.append(["ALL", "{:.2f}".format(all_total), ""])
    return site_totals


loop = asyncio.get_event_loop()
tickers = loop.run_until_complete(fetch())

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

COIN_CONV = [[{'name': t + x,
               'last': tickers[t + x]['last'],
               'pct': tickers[t + x].get('percentChange'),
               'ref': tickers[t + x].get('ref', '24h'),
               }
              for x in COINS if t != x + "_"] for t in ('USDT_', 'BTC_')]

template = Template(
"""{% for c in coins -%}
{{c.name.ljust(16)}} {{c.last.rjust(20)}} {{c.pct.rjust(16)}} {{c.ref.rjust(8)}}
{% endfor -%}""") # noqa

for coins in COIN_CONV:
    print(template.render(coins=sorted(coins, key=lambda x: -float(x['last']))),
          end='--\n')

if len(sys.argv) > 1:
    template = Template(
"""{% for site in sites -%}
{{site[0].ljust(16)}} {{site[1].rjust(20)}} {{site[2].ljust(20)}}
{% endfor -%}""") # noqa
    sites_balance = get_balance(sys.argv[1], tickers)
    print(template.render(
        sites=sorted(sites_balance, key=lambda x: float(x[1])), end='--\n'))
