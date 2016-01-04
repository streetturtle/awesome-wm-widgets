#!/usr/bin/python

import requests
import json

r = requests.get("http://api.fixer.io/latest?symbols=CHF,EUR")
resp = json.loads(r.content)

print resp["rates"]["CHF"]