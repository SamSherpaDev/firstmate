#!/usr/bin/env bash
printf 'nested Pi claimed watcher lifecycle (arm pid=%s)\n' "$$" > "${FM_HOME:?}/state/.nested-arm-claimed"
trap 'exit 0' TERM INT
while :; do sleep 0.1; done
