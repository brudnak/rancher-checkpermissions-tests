#!/bin/bash
# TC005: Non-existent Resource Type

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC005: Non-existent Resource Type ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify handling of invalid resource types"
echo -e "${YELLOW}Expected:${NC} resourcePermissions exists but doesn't contain the invalid resource\n"

INVALID_RESOURCE="management.cattle.io.nonexistentresource"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${INVALID_RESOURCE}"

echo -e "${GREEN}Making request with invalid resource:${NC} ${INVALID_RESOURCE}"
RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check response status
HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")
echo -e "${BLUE}HTTP Status:${NC} ${HTTP_STATUS}"

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "${GREEN}✓${NC} resourcePermissions field is present"
    
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    HAS_INVALID=$(echo "$RESOURCE_PERMS" | jq --arg r "$INVALID_RESOURCE" 'has($r)')
    
    if [ "$HAS_INVALID" == "false" ]; then
        echo -e "${GREEN}✓ PASS:${NC} Invalid resource is not in response (as expected)"
        
        # Check if resourcePermissions is empty
        PERM_COUNT=$(echo "$RESOURCE_PERMS" | jq 'length')
        if [ "$PERM_COUNT" -eq 0 ]; then
            echo -e "${BLUE}Info:${NC} resourcePermissions is empty"
        else
            echo -e "${BLUE}Info:${NC} resourcePermissions contains ${PERM_COUNT} other resource(s)"
        fi
    else
        echo -e "${RED}✗ FAIL:${NC} Invalid resource is present in response"
        echo "$RESOURCE_PERMS" | jq --arg r "$INVALID_RESOURCE" '.[$r]'
    fi
else
    echo -e "${GREEN}✓ PASS:${NC} resourcePermissions field is not present (also acceptable)"
fi

# Verify cluster data is still present
CLUSTER_ID_RESP=$(echo "$RESPONSE" | jq -r '.id')
if [ "$CLUSTER_ID_RESP" == "$CLUSTER_ID" ]; then
    echo -e "${GREEN}✓${NC} Cluster data is intact"
else
    echo -e "${RED}✗${NC} Cluster data may be corrupted"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc005_response.json"
echo "$RESPONSE" | jq '.' > tc005_response.json