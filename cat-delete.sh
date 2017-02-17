#!/bin/bash
YELLOW='\033[0;33m'
NC='\033[0m'

if [ "$#" -ne 2 ]; then
    echo -e "${YELLOW}Usage: $0 [id] [rev]${NC}"
    exit
fi

curl -X DELETE "${CAT_API_URL}?docid=${1}&docrev=${2}"