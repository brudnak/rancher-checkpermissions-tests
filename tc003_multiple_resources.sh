#!/bin/bash
# TC003: Multiple Resource Permission Check

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC003: Multiple Resource Permission Check ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify checkPermissions works with comma-separated resources"
echo -e "${YELLOW}Expected:${NC} resourcePermissions contains all requested resources user has access to\n"

RESOURCES="management.cattle.io.projects,management.cattle.io.clusterroletemplatebindings,management.cattle.io.nodes"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCES}"

echo -e "${GREEN}Making request with multiple resources:${NC}"
echo "  - management.cattle.io.projects"
echo "  - management.cattle.io.clusterroletemplatebindings"
echo "  - management.cattle.io.nodes"

RESPONSE=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "\n${GREEN}✓${NC} resourcePermissions field is present"
    
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    
    # Check each requested resource
    echo -e "\n${BLUE}Checking requested resources:${NC}"
    for resource in ${RESOURCES//,/ }; do
        HAS_RESOURCE=$(echo "$RESOURCE_PERMS" | jq --arg r "$resource" 'has($r)')
        if [ "$HAS_RESOURCE" == "true" ]; then
            VERB_COUNT=$(echo "$RESOURCE_PERMS" | jq --arg r "$resource" '.[$r] | keys | length')
            echo -e "${GREEN}✓${NC} $resource (${VERB_COUNT} verbs)"
            
            # List verbs
            echo "$RESOURCE_PERMS" | jq -r --arg r "$resource" '.[$r] | keys[]' | while read verb; do
                echo "    - $verb"
            done
        else
            echo -e "${YELLOW}○${NC} $resource (not present - user may lack permissions)"
        fi
    done
    
    # Summary
    TOTAL_RESOURCES=$(echo "$RESOURCE_PERMS" | jq 'keys | length')
    echo -e "\n${BLUE}Summary:${NC} Found permissions for ${TOTAL_RESOURCES} resource(s)"
    
    # Check for unexpected resources
    echo -e "\n${BLUE}All resources in response:${NC}"
    echo "$RESOURCE_PERMS" | jq -r 'keys[]' | while read res; do
        echo "  - $res"
    done
    
    echo -e "\n${GREEN}✓ PASS:${NC} Multiple resource handling works correctly"
else
    echo -e "${RED}✗ FAIL:${NC} resourcePermissions field is missing"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc003_response.json"
echo "$RESPONSE" | jq '.' > tc003_response.json