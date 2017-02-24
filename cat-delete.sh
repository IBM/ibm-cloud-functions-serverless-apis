#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo -e "Usage: $0 [id]"
    exit
fi

curl -X DELETE "${CAT_API_URL}?id=${1}"
