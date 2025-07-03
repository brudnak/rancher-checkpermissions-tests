#!/bin/bash
# TC006: Mixed Valid and Invalid Resources

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC006: Mixed Valid and Invalid Resources ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify system filters out invalid resources"
echo -e "${YELLOW}Expected:${NC} Only valid resources appear in resourcePermissions\n"

RESOURCES="management.cattle.io.projects,management.cattle.io.invalidresource,management.cattle.io.clusterroletemplatebindings,management.cattle.io.fakeresource"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCES}"

echo -e "${GREEN}Making request with mixed resources:${NC}"
echo "  Valid:"
echo "    - management.cattle.io.projects"
echo "    - management.cattle.io.clusterroletemplatebindings"
echo "  Invalid:"
echo "    - management.cattle.io.invalidresource"
echo "    - management.cattle.io.fakeresource"

RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Define valid and invalid resources
VALID_RESOURCES=("management.cattle.io.projects" "management.cattle.io.clusterroletemplatebindings")
INVALID_RESOURCES=("management.cattle.io.invalidresource" "management.cattle.io.fakeresource")

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "\n${GREEN}✓${NC} resourcePermissions field is present"
    
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    
    # Check valid resources
    echo -e "\n${BLUE}Checking valid resources:${NC}"
    VALID_COUNT=0
    for resource in "${VALID_RESOURCES[@]}"; do
        HAS_RESOURCE=$(echo "$RESOURCE_PERMS" | jq --arg r "$resource" 'has($r)')
        if [ "$HAS_RESOURCE" == "true" ]; then
            echo -e "${GREEN}✓${NC} $resource is present"
            ((VALID_COUNT++))
        else
            echo -e "${YELLOW}○${NC} $resource is not present (user may lack permissions)"
        fi
    done
    
    # Check invalid resources
    echo -e "\n${BLUE}Checking invalid resources (should NOT be present):${NC}"
    INVALID_FOUND=0
    for resource in "${INVALID_RESOURCES[@]}"; do
        HAS_RESOURCE=$(echo "$RESOURCE_PERMS" | jq --arg r "$resource" 'has($r)')
        if [ "$HAS_RESOURCE" == "false" ]; then
            echo -e "${GREEN}✓${NC} $resource is correctly absent"
        else
            echo -e "${RED}✗${NC} $resource is present (should not be)"
            ((INVALID_FOUND++))
        fi
    done
    
    # Summary
    TOTAL_RESOURCES=$(echo "$RESOURCE_PERMS" | jq 'keys | length')
    echo -e "\n${BLUE}Summary:${NC}"
    echo "  - Total resources in response: ${TOTAL_RESOURCES}"
    echo "  - Valid resources found: ${VALID_COUNT}"
    echo "  - Invalid resources found: ${INVALID_FOUND}"
    
    if [ "$INVALID_FOUND" -eq 0 ]; then
        echo -e "\n${GREEN}✓ PASS:${NC} Invalid resources are correctly filtered out"
    else
        echo -e "\n${RED}✗ FAIL:${NC} Invalid resources were not filtered"
    fi
    
    # List all resources in response
    echo -e "\n${BLUE}All resources in response:${NC}"
    echo "$RESOURCE_PERMS" | jq -r 'keys[]' | while read res; do
        echo "  - $res"
    done
else
    echo -e "${YELLOW}⚠ WARNING:${NC} resourcePermissions field is not present"
    echo "This could mean the user has no permissions for any requested resources"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc006_response.json"
echo "$RESPONSE" | jq '.' > tc006_response.json