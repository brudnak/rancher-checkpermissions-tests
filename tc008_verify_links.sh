#!/bin/bash
# TC008: Verify Verb Links Format

# Source configuration
source ./config.sh

echo -e "${BLUE}=== TC008: Verify Verb Links Format ===${NC}"
echo -e "${YELLOW}Objective:${NC} Validate the format of permission links"
echo -e "${YELLOW}Expected:${NC} Each verb has a properly formatted URL\n"

# Build query parameters
RESOURCES="management.cattle.io.projects,management.cattle.io.clusterroletemplatebindings"
URL="${RANCHER_URL}/v1/management.cattle.io.clusters/${CLUSTER_ID}?checkPermissions=${RESOURCES}"

echo -e "${GREEN}Making request for resources:${NC}"
echo "  - management.cattle.io.projects"
echo "  - management.cattle.io.clusterroletemplatebindings"

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
    
    # Check if resourcePermissions is empty
    if [ "$(echo "$RESOURCE_PERMS" | jq 'length')" -eq 0 ]; then
        echo -e "${YELLOW}⚠ WARNING:${NC} resourcePermissions is empty"
        echo "User may not have permissions for the requested resources"
        exit 0
    fi
    
    # Valid verbs we expect
    VALID_VERBS=("get" "list" "watch" "create" "update" "delete" "patch")
    
    echo -e "\n${BLUE}Validating link formats:${NC}"
    
    # Use a simple flag to track overall pass/fail
    ALL_VALID=true
    VERB_COUNT=0
    
    # Process each resource
    for resource in $(echo "$RESOURCE_PERMS" | jq -r 'keys[]'); do
        echo -e "\n${YELLOW}Resource:${NC} $resource"
        
        # Get all verbs for this resource
        VERBS=$(echo "$RESOURCE_PERMS" | jq -r --arg r "$resource" '.[$r] | keys[]')
        
        for verb in $VERBS; do
            ((VERB_COUNT++))
            
            # Get the link for this verb
            LINK=$(echo "$RESOURCE_PERMS" | jq -r --arg r "$resource" --arg v "$verb" '.[$r][$v]')
            
            # Check if verb is valid
            if [[ " ${VALID_VERBS[@]} " =~ " ${verb} " ]]; then
                echo -e "  ${GREEN}✓${NC} Verb: $verb"
            else
                echo -e "  ${YELLOW}⚠${NC} Unexpected verb: $verb"
            fi
            
            # Validate link format
            if [[ "$LINK" =~ ^https?://.*/v1/.*$ ]]; then
                echo -e "    ${GREEN}✓${NC} Valid URL format"
                
                # Check if link contains the resource type
                if [[ "$LINK" == *"$resource"* ]]; then
                    echo -e "    ${GREEN}✓${NC} URL contains resource type"
                else
                    echo -e "    ${YELLOW}⚠${NC} URL doesn't contain resource type"
                    ALL_VALID=false
                fi
                
                # Check if link ends with cluster ID
                if [[ "$LINK" == *"/${CLUSTER_ID}"* ]] || [[ "$LINK" == *"/${CLUSTER_ID}" ]]; then
                    echo -e "    ${GREEN}✓${NC} URL contains cluster ID"
                else
                    echo -e "    ${YELLOW}⚠${NC} URL doesn't contain cluster ID"
                    ALL_VALID=false
                fi
            else
                echo -e "    ${RED}✗${NC} Invalid URL format: $LINK"
                ALL_VALID=false
            fi
        done
    done
    
    echo -e "\n${BLUE}Summary:${NC}"
    echo "  - Total verbs checked: ${VERB_COUNT}"
    
    if [ "$ALL_VALID" = true ]; then
        echo -e "\n${GREEN}✓ PASS:${NC} All links are properly formatted"
    else
        echo -e "\n${RED}✗ FAIL:${NC} Some links have formatting issues"
    fi
    
    # Show example of expected format
    echo -e "\n${BLUE}Expected link format:${NC}"
    echo "  ${RANCHER_URL}/v1/<resource-type>/<cluster-id>"
else
    echo -e "${YELLOW}⚠ WARNING:${NC} No resourcePermissions to validate"
fi

echo -e "\n${BLUE}Full response stored in:${NC} tc008_response.json"
echo "$RESPONSE" | jq '.' > tc008_response.json