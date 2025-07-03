#!/bin/bash
# Cleanup script for checkPermissions tests

# Source configuration for colors
source ./config.sh 2>/dev/null || {
    # Define colors if config.sh doesn't exist
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}

echo -e "${BLUE}=== Cleaning up test artifacts ===${NC}\n"

# Count JSON files
JSON_COUNT=$(ls -1 tc*_response.json 2>/dev/null | wc -l)

if [ "$JSON_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No JSON response files found to clean.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${JSON_COUNT} JSON response files:${NC}"
ls -1 tc*_response.json 2>/dev/null | while read file; do
    echo "  - $file"
done

echo -e "\n${YELLOW}Do you want to delete these files? (y/N):${NC} "
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "\n${GREEN}Deleting JSON response files...${NC}"
    rm -f tc*_response.json
    echo -e "${GREEN}✓ Cleanup complete!${NC}"
else
    echo -e "\n${BLUE}Cleanup cancelled. Files were not deleted.${NC}"
fi

# Optional: Clean other artifacts
if [ -f "config.sh" ]; then
    echo -e "\n${YELLOW}Keep config.sh? (Y/n):${NC} "
    read -r response
    if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        rm -f config.sh
        echo -e "${GREEN}✓ config.sh removed${NC}"
    fi
fi