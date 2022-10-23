#!/usr/bin/with-contenv bash

CONFIG_PATH=/data/options.json

export PORT=$(jq --raw-output ".port" $CONFIG_PATH)
export COMMUNITY_STRING=$(jq --raw-output ".community_string" $CONFIG_PATH)
export PYTHONUNBUFFERED=1

exec python3 trap.py
