#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo -e "Usage: $0 [name of cat] [color of cat]"
    exit
fi

CAT_API_URL=`ibmcloud fn api list | tail -1 | awk '{print $5}'`

curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"'$1'","color":"'$2'"}' \
  $CAT_API_URL
