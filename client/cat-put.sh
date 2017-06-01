#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo -e "Usage: $0 [id] [name of cat] [color of cat]"
    exit
fi

CAT_API_URL=`wsk api list | tail -1 | awk '{print $5}'`

curl -X PUT -d "{\"id\":\"$1\", \"name\":\"$2\", \"color\":\"$3\"}" $CAT_API_URL
