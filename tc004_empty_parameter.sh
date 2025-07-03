#!/bin/bash
# TC004: Empty checkPermissions Parameter

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC004: Empty checkPermissions Parameter ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify behavior when checkPermissions is present but empty"
echo -e "${YELLOW}Expected:${NC} Normal cluster response without resourcePermissions field\n"

URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions="

echo -e "${GREEN}Making request with empty checkPermissions parameter${NC}"
RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "false" ]; then
    echo -e "${GREEN}✓ PASS:${NC} resourcePermissions field is not present (as expected)"
else
    echo -e "${YELLOW}⚠ NOTE:${NC} resourcePermissions field is present"
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    
    # Check if it's empty
    if [ "$(echo "$RESOURCE_PERMS" | jq 'length')" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS:${NC} resourcePermissions is empty (acceptable behavior)"
    else
        echo -e "${RED}✗ FAIL:${NC} resourcePermissions contains data (not expected)"
        echo "$RESOURCE_PERMS" | jq '.'
    fi
fi

# Verify we still get cluster data
CLUSTER_NAME=$(echo "$RESPONSE" | jq -r '.spec.displayName // .name')
if [ -n "$CLUSTER_NAME" ] && [ "$CLUSTER_NAME" != "null" ]; then
    echo -e "${GREEN}✓${NC} Cluster data is present: ${CLUSTER_NAME}"
else
    echo -e "${RED}✗${NC} Cluster data appears to be missing"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc004_response.json"
echo "$RESPONSE" | jq '.' > tc004_response.json