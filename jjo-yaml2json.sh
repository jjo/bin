#!/bin/sh
python3 -c 'import yaml,json,sys;print(json.dumps(yaml.load(sys.stdin, Loader=yaml.SafeLoader)))'
