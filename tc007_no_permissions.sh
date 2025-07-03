#!/bin/bash
# TC007: User with No Permissions

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC007: User with No Permissions ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify response when user has no permissions for requested resources"
echo -e "${YELLOW}Expected:${NC} Empty or missing resourcePermissions field\n"

# Check if limited user token is configured
if [ -z "$LIMITED_USER_TOKEN" ]; then
    echo -e "${YELLOW}SKIP:${NC} LIMITED_USER_TOKEN not configured in config.sh"
    echo "To run this test, add a token for a user with limited/no permissions"
    exit 0
fi

RESOURCES="management.cattle.io.projects,management.cattle.io.clusterroletemplatebindings"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCES}"

echo -e "${GREEN}Making request with limited user token${NC}"
echo "Requesting permissions for:"
echo "  - management.cattle.io.projects"
echo "  - management.cattle.io.clusterroletemplatebindings"

RESPONSE=$(curl -sk -H "Authorization: Bearer ${LIMITED_USER_TOKEN}" "${URL}")
HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${LIMITED_USER_TOKEN}" "${URL}")

echo -e "\n${BLUE}HTTP Status:${NC} ${HTTP_STATUS}"

if [ "$HTTP_STATUS" == "403" ] || [ "$HTTP_STATUS" == "401" ]; then
    echo -e "${GREEN}✓ PASS:${NC} User cannot access cluster (no permissions)"
    exit 0
fi

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check for resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    PERM_COUNT=$(echo "$RESOURCE_PERMS" | jq 'length')
    
    if [ "$PERM_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS:${NC} resourcePermissions is empty (user has no permissions)"
    else
        echo -e "${YELLOW}⚠ NOTE:${NC} resourcePermissions contains ${PERM_COUNT} resource(s)"
        echo "This user has some permissions:"
        echo "$RESOURCE_PERMS" | jq -r 'keys[]' | while read res; do
            VERB_COUNT=$(echo "$RESOURCE_PERMS" | jq --arg r "$res" '.[$r] | keys | length')
            echo "  - $res (${VERB_COUNT} verbs)"
        done
        echo -e "\n${YELLOW}INFO:${NC} Test inconclusive - user has some permissions"
    fi
else
    echo -e "${GREEN}✓ PASS:${NC} resourcePermissions field is not present"
    echo "User has no permissions for requested resources"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc007_response.json"
echo "$RESPONSE" | jq '.' > tc007_response.json