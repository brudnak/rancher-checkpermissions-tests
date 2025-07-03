#!/bin/bash
# TC009: Special Characters and URL Encoding

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC009: Special Characters and URL Encoding ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify URL encoding is handled correctly"
echo -e "${YELLOW}Expected:${NC} Properly encoded request returns valid response\n"

# Test with different encoding scenarios
RESOURCES="management.cattle.io.projects,management.cattle.io.clusterroletemplatebindings"

echo -e "${GREEN}Test 1: Standard encoding${NC}"
URL1="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCES}"
echo "URL: $URL1"

RESPONSE1=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL1}")
if [ $? -eq 0 ]; then
    HAS_PERMS1=$(echo "$RESPONSE1" | jq 'has("resourcePermissions")')
    if [ "$HAS_PERMS1" == "true" ]; then
        echo -e "${GREEN}✓ PASS:${NC} Standard encoding works"
        COUNT1=$(echo "$RESPONSE1" | jq '.resourcePermissions | keys | length')
        echo "  Resources found: $COUNT1"
    else
        echo -e "${YELLOW}⚠${NC} No resourcePermissions in response"
    fi
else
    echo -e "${RED}✗ FAIL:${NC} Request failed"
fi

echo -e "\n${GREEN}Test 2: URL encoded parameter${NC}"
# URL encode the entire parameter value
ENCODED_RESOURCES=$(printf '%s' "$RESOURCES" | jq -sRr @uri)
URL2="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${ENCODED_RESOURCES}"
echo "Encoded resources: $ENCODED_RESOURCES"

RESPONSE2=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL2}")
if [ $? -eq 0 ]; then
    HAS_PERMS2=$(echo "$RESPONSE2" | jq 'has("resourcePermissions")')
    if [ "$HAS_PERMS2" == "true" ]; then
        echo -e "${GREEN}✓ PASS:${NC} URL encoded parameter works"
        COUNT2=$(echo "$RESPONSE2" | jq '.resourcePermissions | keys | length')
        echo "  Resources found: $COUNT2"
    else
        echo -e "${YELLOW}⚠${NC} No resourcePermissions in response"
    fi
else
    echo -e "${RED}✗ FAIL:${NC} Request failed"
fi

echo -e "\n${GREEN}Test 3: Spaces in parameter (encoded as %20)${NC}"
# Test with spaces (should be encoded)
RESOURCES_WITH_SPACES="management.cattle.io.projects, management.cattle.io.clusterroletemplatebindings"
URL3="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=$(printf '%s' "$RESOURCES_WITH_SPACES" | sed 's/ /%20/g')"
echo "Testing with spaces encoded as %20"

RESPONSE3=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" "${URL3}")
if [ $? -eq 0 ]; then
    HAS_PERMS3=$(echo "$RESPONSE3" | jq 'has("resourcePermissions")')
    if [ "$HAS_PERMS3" == "true" ]; then
        echo -e "${GREEN}✓${NC} Request succeeded with encoded spaces"
        COUNT3=$(echo "$RESPONSE3" | jq '.resourcePermissions | keys | length')
        echo "  Resources found: $COUNT3"
    else
        echo -e "${YELLOW}⚠${NC} No resourcePermissions in response"
    fi
else
    echo -e "${RED}✗${NC} Request failed"
fi

echo -e "\n${GREEN}Test 4: Using curl --data-urlencode${NC}"
# Use curl's built-in URL encoding
RESPONSE4=$(curl -sk -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -G "${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}" \
    --data-urlencode "checkPermissions=${RESOURCES}")

if [ $? -eq 0 ]; then
    HAS_PERMS4=$(echo "$RESPONSE4" | jq 'has("resourcePermissions")')
    if [ "$HAS_PERMS4" == "true" ]; then
        echo -e "${GREEN}✓ PASS:${NC} curl --data-urlencode works"
        COUNT4=$(echo "$RESPONSE4" | jq '.resourcePermissions | keys | length')
        echo "  Resources found: $COUNT4"
    else
        echo -e "${YELLOW}⚠${NC} No resourcePermissions in response"
    fi
else
    echo -e "${RED}✗ FAIL:${NC} Request failed"
fi

echo -e "\n${BLUE}Summary:${NC}"
echo "Different encoding methods should all produce the same result"

# Save the last response
echo -e "\n${BLUE}Full response stored in:${NC} tc009_response.json"
echo "$RESPONSE4" | jq '.' > tc009_response.json