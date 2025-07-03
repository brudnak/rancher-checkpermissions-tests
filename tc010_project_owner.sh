#!/bin/bash
# TC010: Project Owner Permissions Check

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC010: Project Owner Permissions Check ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify project owner has full permissions for project resources"
echo -e "${YELLOW}Expected:${NC} Project owner should have all CRUD permissions for projectroletemplatebindings\n"

# Check if PROJECT_OWNER_TOKEN is set
if [ -z "$PROJECT_OWNER_TOKEN" ]; then
    echo -e "${RED}ERROR: PROJECT_OWNER_TOKEN not set in config.sh${NC}"
    exit 1
fi

# Check if PROJECT_ID and CLUSTER_ID are passed as arguments or set in config
PROJECT_ID="${1:-$PROJECT_ID}"
CLUSTER_ID="${2:-$CLUSTER_ID}"

if [ -z "$PROJECT_ID" ] || [ -z "$CLUSTER_ID" ]; then
    echo -e "${RED}ERROR: Usage: $0 <PROJECT_ID> <CLUSTER_ID>${NC}"
    echo "Or set PROJECT_ID and CLUSTER_ID in config.sh"
    exit 1
fi

echo -e "${BLUE}Testing with:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Cluster ID: $CLUSTER_ID"
echo "  User Type: Project Owner"

# Test using individual project endpoint with SLASH format (not colon)
echo -e "\n${GREEN}Checking permissions via project endpoint:${NC}"
PROJECT_URL="${RANCHER_URL}/v1/management.cattle.io.projects/${CLUSTER_ID}/${PROJECT_ID}?checkPermissions=management.cattle.io.projectroletemplatebindings"
echo "URL: $PROJECT_URL"

RESPONSE=$(curl -sk -H "Authorization: Bearer ${PROJECT_OWNER_TOKEN}" "${PROJECT_URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check if we got a valid project response
PROJECT_NAME=$(echo "$RESPONSE" | jq -r '.spec.displayName // .name // empty')
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}ERROR: Invalid response - may be using wrong URL format${NC}"
    echo -e "${YELLOW}Note: Use slash (/) not colon (:) in project ID${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found project: $PROJECT_NAME"

# Check resourcePermissions
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "${GREEN}✓${NC} resourcePermissions field is present"
    
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    
    # Check PRTB permissions
    PRTB_PERMS=$(echo "$RESOURCE_PERMS" | jq '.["management.cattle.io.projectroletemplatebindings"] // {}')
    if [ "$PRTB_PERMS" != "{}" ]; then
        echo -e "\n${BLUE}Project Role Template Binding permissions:${NC}"
        echo "$PRTB_PERMS" | jq -r 'keys[]' | while read verb; do
            echo "  ✓ $verb"
        done
        
        # Check for all CRUD permissions
        HAS_CREATE=$(echo "$PRTB_PERMS" | jq 'has("create")')
        HAS_DELETE=$(echo "$PRTB_PERMS" | jq 'has("delete")')
        HAS_UPDATE=$(echo "$PRTB_PERMS" | jq 'has("update")')
        HAS_LIST=$(echo "$PRTB_PERMS" | jq 'has("list")')
        HAS_GET=$(echo "$PRTB_PERMS" | jq 'has("get")')
        
        if [ "$HAS_CREATE" == "true" ] && [ "$HAS_DELETE" == "true" ] && [ "$HAS_UPDATE" == "true" ] && [ "$HAS_LIST" == "true" ] && [ "$HAS_GET" == "true" ]; then
            echo -e "\n${GREEN}✓ PASS:${NC} Project owner has full CRUD permissions for projectroletemplatebindings"
            echo "  (This confirms they can fully manage project members)"
        else
            echo -e "\n${YELLOW}⚠ WARNING:${NC} Project owner missing some expected permissions"
        fi
    else
        echo -e "${RED}✗ FAIL:${NC} No PRTB permissions found"
    fi
else
    echo -e "${RED}✗ FAIL:${NC} resourcePermissions field is missing"
fi

# Test the wrong format to show the difference
echo -e "\n${BLUE}Testing with colon format (expected to fail):${NC}"
COLON_URL="${RANCHER_URL}/v1/management.cattle.io.projects/${CLUSTER_ID}:${PROJECT_ID}?checkPermissions=management.cattle.io.projectroletemplatebindings"
COLON_RESPONSE=$(curl -sk -H "Authorization: Bearer ${PROJECT_OWNER_TOKEN}" "${COLON_URL}" | jq '.type // empty')
if [ "$COLON_RESPONSE" == "collection" ]; then
    echo -e "${GREEN}✓${NC} Colon format returns collection (as discovered)"
    echo "  This is why the test was failing initially"
fi

# Also test cluster endpoint to show it doesn't work there
echo -e "\n${BLUE}Testing cluster endpoint (expected to be empty):${NC}"
CLUSTER_URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=management.cattle.io.projectroletemplatebindings"
CLUSTER_RESPONSE=$(curl -sk -H "Authorization: Bearer ${PROJECT_OWNER_TOKEN}" "${CLUSTER_URL}" | jq '.resourcePermissions // {}')
if [ "$CLUSTER_RESPONSE" == "{}" ]; then
    echo -e "${GREEN}✓${NC} Cluster endpoint returns empty permissions (as expected)"
fi

echo -e "\n${BLUE}Summary:${NC}"
echo "- Project owner permissions ARE exposed via checkPermissions"
echo "- Must use project endpoint with SLASH format: /cluster-id/project-id"
echo "- Colon format (/cluster-id:project-id) returns empty collection"
echo "- Cluster endpoint doesn't show project-level permissions"

echo -e "\n${BLUE}Full response stored in:${NC} tc010_response.json"
echo "$RESPONSE" | jq '.' > tc010_response.json