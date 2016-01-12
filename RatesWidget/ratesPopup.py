#!/usr/bin/python

import requests
import json

r = requests.get("http://api.fixer.io/latest?symbols=USD,EUR,JPY,GBP,CHF,CAD,RUB")
resp = json.loads(r.content)
rates = resp["rates"]

for currency, rate in rates.items():
    print currency, rate
