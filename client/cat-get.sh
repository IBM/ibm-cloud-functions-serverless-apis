#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo -e "Usage: $0 [id]"
    exit
fi

CAT_API_URL=`ibmcloud fn api list | tail -1 | awk '{print $5}'`

curl ${CAT_API_URL}?id=${1}
