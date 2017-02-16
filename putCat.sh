#!/bin/bash
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$#" -ne 4 ]; then
    echo -e "${YELLOW}Usage: $0 [id] [rev] [name of cat] [color of cat]${NC}"
    exit
fi

curl -X PUT -d "{\"_id\":\"$1\", \"_rev\": \"$2\", \"name\":\"$3\", \"color\":\"$4\"}" $CAT_API_URL