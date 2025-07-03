#!/bin/bash
# TC001: Baseline - Cluster without checkPermissions

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC001: Baseline - Cluster without checkPermissions ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify standard cluster endpoint behavior without the new parameter"
echo -e "${YELLOW}Expected:${NC} Normal cluster response without resourcePermissions field\n"

# Make the request
echo -e "${GREEN}Making request to:${NC} ${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}"
RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" \
  "${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}")

# Check if request was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Parse and validate response
echo -e "\n${GREEN}Response received. Checking for resourcePermissions field...${NC}"
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "false" ]; then
    echo -e "${GREEN}✓ PASS:${NC} resourcePermissions field is not present (as expected)"
    
    # Show cluster name to confirm valid response
    CLUSTER_NAME=$(echo "$RESPONSE" | jq -r '.spec.displayName // .name')
    echo -e "${BLUE}Cluster name:${NC} ${CLUSTER_NAME}"
else
    echo -e "${RED}✗ FAIL:${NC} resourcePermissions field is present (not expected)"
    echo "$RESPONSE" | jq '.resourcePermissions'
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc001_response.json"
echo "$RESPONSE" | jq '.' > tc001_response.json