#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo -e "Usage: $0 [name of cat] [color of cat]"
    exit
fi

curl -X POST -d "{\"name\":\"$1\",\"color\":\"$2\"}" $CAT_API_URL
