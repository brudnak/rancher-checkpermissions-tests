#!/bin/bash
# TC011: Project Member Permissions Check

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC011: Project Member Permissions Check ===${NC}"
echo -e "${YELLOW}Objective:${NC} Verify project member with 'Manage Project Members' role permissions"
echo -e "${YELLOW}Expected:${NC} Should have create permission for projectroletemplatebindings but limited project permissions\n"

# Check if PROJECT_MEMBER_TOKEN is set
if [ -z "$PROJECT_MEMBER_TOKEN" ]; then
    echo -e "${RED}ERROR: PROJECT_MEMBER_TOKEN not set in config.sh${NC}"
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
echo "  User Type: Project Member (with Manage Project Members role)"

# Test cluster-level permissions for project resources
echo -e "\n${GREEN}Checking permissions via cluster endpoint:${NC}"
CLUSTER_URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=management.cattle.io.projectroletemplatebindings,management.cattle.io.projects"

RESPONSE=$(curl -sk -H "Authorization: Bearer ${PROJECT_MEMBER_TOKEN}" "${CLUSTER_URL}")

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to make request${NC}"
    exit 1
fi

# Check response
HAS_RESOURCE_PERMS=$(echo "$RESPONSE" | jq 'has("resourcePermissions")')

if [ "$HAS_RESOURCE_PERMS" == "true" ]; then
    echo -e "${GREEN}✓${NC} resourcePermissions field is present"
    
    RESOURCE_PERMS=$(echo "$RESPONSE" | jq '.resourcePermissions')
    
    # Check project permissions
    echo -e "\n${BLUE}Project permissions:${NC}"
    PROJECT_PERMS=$(echo "$RESOURCE_PERMS" | jq '.["management.cattle.io.projects"] // {}')
    if [ "$PROJECT_PERMS" != "{}" ]; then
        echo "$PROJECT_PERMS" | jq -r 'keys[]' | while read verb; do
            echo "  ✓ $verb"
        done
        
        # Check that member does NOT have dangerous permissions
        HAS_UPDATE=$(echo "$PROJECT_PERMS" | jq 'has("update")')
        HAS_DELETE=$(echo "$PROJECT_PERMS" | jq 'has("delete")')
        if [ "$HAS_UPDATE" == "false" ] && [ "$HAS_DELETE" == "false" ]; then
            echo -e "${GREEN}✓ PASS:${NC} Project member correctly lacks update/delete permissions"
        else
            echo -e "${YELLOW}⚠ WARNING:${NC} Project member has elevated permissions (update/delete)"
        fi
    else
        echo -e "${GREEN}✓${NC} No project permissions (expected for regular member)"
    fi
    
    # Check PRTB permissions - THIS IS THE KEY TEST
    echo -e "\n${BLUE}Project Role Template Binding permissions:${NC}"
    PRTB_PERMS=$(echo "$RESOURCE_PERMS" | jq '.["management.cattle.io.projectroletemplatebindings"] // {}')
    if [ "$PRTB_PERMS" != "{}" ]; then
        echo "$PRTB_PERMS" | jq -r 'keys[]' | while read verb; do
            echo "  ✓ $verb"
        done
        
        # Check for create permission (critical for managing members)
        HAS_CREATE=$(echo "$PRTB_PERMS" | jq 'has("create")')
        if [ "$HAS_CREATE" == "true" ]; then
            echo -e "${GREEN}✓ PASS:${NC} Member with 'Manage Project Members' role CAN create bindings"
            echo "  (This allows them to manage project members)"
        else
            echo -e "${RED}✗ FAIL:${NC} Member cannot create project role template bindings"
            echo "  (They should be able to if they have 'Manage Project Members' role)"
        fi
        
        # They might also have list/get permissions
        HAS_LIST=$(echo "$PRTB_PERMS" | jq 'has("list")')
        HAS_GET=$(echo "$PRTB_PERMS" | jq 'has("get")')
        if [ "$HAS_LIST" == "true" ] || [ "$HAS_GET" == "true" ]; then
            echo -e "${GREEN}✓${NC} Can view existing project members"
        fi
    else
        echo -e "${RED}✗ FAIL:${NC} No PRTB permissions found"
        echo "  (Member with 'Manage Project Members' role should have these permissions)"
    fi
else
    echo -e "${YELLOW}⚠ WARNING:${NC} resourcePermissions field is missing"
    echo "  (This might mean the member has no cluster access)"
fi

# Test if we can access the project directly
echo -e "\n${GREEN}Verifying project access:${NC}"
PROJECT_RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${PROJECT_MEMBER_TOKEN}" \
    "${RANCHER_URL}/v1/management.cattle.io.projects/${PROJECT_ID}")

if [ "$PROJECT_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓${NC} Can access project (HTTP 200)"
else
    echo -e "${YELLOW}○${NC} Cannot directly access project (HTTP $PROJECT_RESPONSE)"
    echo "  (This is OK if they can still manage members via bindings)"
fi

echo -e "\n${BLUE}Summary:${NC}"
echo "This test verifies that users with 'Manage Project Members' role can be detected"
echo "via the checkPermissions parameter. The UI needs this to show member management"
echo "features to non-owner users who have the appropriate role."

echo -e "\n${BLUE}Full response stored in:${NC} tc011_response.json"
echo "$RESPONSE" | jq '.' > tc011_response.json