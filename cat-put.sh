#!/bin/bash
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$#" -ne 3 ]; then
    echo -e "${YELLOW}Usage: $0 [id] [name of cat] [color of cat]${NC}"
    exit
fi

curl -X PUT -d "{\"id\":\"$1\", \"name\":\"$2\", \"color\":\"$3\"}" $CAT_API_URL