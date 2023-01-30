#!/bin/bash

BATTERY=$(upower --dump | grep keyboard -A 7 | grep percentage | awk -F' ' '{print $2}')

if [ ! -z $BATTERY ]; then
  echo "KB ${BATTERY}"
fi

