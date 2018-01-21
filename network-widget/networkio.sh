#!/usr/bin/env bash

ACTIVE_INTERFACE="$(ip -o link show | awk '$9~/UP/{sub(":","",$2);print $2}')"

IO="$(cat /proc/net/dev | grep ${ACTIVE_INTERFACE} | sed "s/.*://" | awk '{printf $1";"$9}')"

echo "${IO}"
