#!/bin/bash

ARGS=$@

# start SmartHomeNG
python3 /usr/local/smarthome/bin/smarthome.py "$ARGS"

# workaround because SmartHomeNG default forks to background
while :; do
  sleep 300
done
