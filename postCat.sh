#!/bin/bash
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$#" -ne 2 ]; then
    echo -e "${YELLOW}Usage: $0 [name of cat] [color of cat]${NC}"
    exit
fi

curl -X POST -d "{\"name\":\"$1\",\"color\":\"$2\"}" $CAT_API_URL
