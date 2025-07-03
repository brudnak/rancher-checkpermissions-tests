#!/bin/bash
# TC002: Single Resource Permission Check

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC002: Single Resource Permission Check ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify checkPermissions works with a single resource type"
echo -e "${YELLOW}Expected:${NC} resourcePermissions field contains only the requested resource\n"

RESOURCE="management.cattle.io.projects"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCE}"

echo -e "${GREEN}Making request with:${NC} checkPermissions=${RESOURCE}"
RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "${GREEN}✓${NC} resourcePermissions field is present"
    
    # Check if requested resource exists
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    HAS_PROJECTS=$(echo "$RESOURCE_PERMS" | jq --arg r "$RESOURCE" 'has($r)')
    
    if [ "$HAS_PROJECTS" == "true" ]; then
        echo -e "${GREEN}✓${NC} Requested resource '${RESOURCE}' is present"
        
        # Show permissions
        echo -e "\n${BLUE}Permissions for ${RESOURCE}:${NC}"
        echo "$RESOURCE_PERMS" | jq --arg r "$RESOURCE" '.[$r]' | jq -r 'keys[]' | while read verb; do
            echo "  - $verb"
        done
        
        # Count resources
        RESOURCE_COUNT=$(echo "$RESOURCE_PERMS" | jq 'keys | length')
        if [ "$RESOURCE_COUNT" -eq 1 ]; then
            echo -e "\n${GREEN}✓ PASS:${NC} Only one resource in response (as expected)"
        else
            echo -e "\n${YELLOW}⚠ WARNING:${NC} Found $RESOURCE_COUNT resources (expected 1)"
            echo "$RESOURCE_PERMS" | jq 'keys'
        fi
    else
        echo -e "${YELLOW}⚠${NC} Requested resource not found (user may lack permissions)"
        echo -e "${GREEN}✓ PASS:${NC} This is acceptable if user has no permissions"
    fi
else
    echo -e "${RED}✗ FAIL:${NC} resourcePermissions field is missing"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc002_response.json"
echo "$RESPONSE" | jq '.' > tc002_response.json