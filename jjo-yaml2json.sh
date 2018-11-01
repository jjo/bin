#!/bin/sh
python -c 'import yaml,json,sys;print(json.dumps(yaml.load(sys.stdin)))'
