#!/bin/bash

ARGS=$@

# start SmartHomeNG
cd /usr/local/smarthome/
python3 bin/smarthome.py "$ARGS"

# workaround because SmartHomeNG default forks to background
while :; do
  sleep 300
done
