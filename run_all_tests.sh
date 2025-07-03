#!/bin/bash
# Run all checkPermissions tests

# Source configuration
source ./config.sh

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Running All CheckPermissions Tests${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check if config exists
if [ ! -f "./config.sh" ]; then
    echo -e "${RED}ERROR: config.sh not found${NC}"
    echo "Please create config.sh from config.sh.template"
    exit 1
fi

# Make all test scripts executable
chmod +x tc*.sh

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Run each test
for test_script in tc*.sh; do
    if [ -f "$test_script" ]; then
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Running: $test_script${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        ((TOTAL_TESTS++))
        
        # Special handling for project tests that need parameters
        if [[ "$test_script" == "tc010_project_owner.sh" ]] || [[ "$test_script" == "tc011_project_member.sh" ]]; then
            if [ -z "$PROJECT_ID" ] || [ -z "$CLUSTER_ID" ]; then
                echo -e "${YELLOW}SKIP: $test_script requires PROJECT_ID and CLUSTER_ID${NC}"
                echo "Set these in config.sh or run manually with: ./$test_script <PROJECT_ID> <CLUSTER_ID>"
                ((SKIPPED_TESTS++))
                continue
            fi
            # Run with parameters
            ./"$test_script" "$PROJECT_ID" "$CLUSTER_ID"
            TEST_RESULT=$?
        else
            # Run normally
            ./"$test_script"
            TEST_RESULT=$?
        fi
        
        # Check result
        if [ $TEST_RESULT -eq 0 ]; then
            # Check if test was skipped (look for SKIP in output)
            if ./"$test_script" 2>&1 | grep -q "SKIP:"; then
                ((SKIPPED_TESTS++))
            else
                ((PASSED_TESTS++))
            fi
        else
            ((FAILED_TESTS++))
        fi
        
        echo -e "\n${BLUE}Press Enter to continue to next test...${NC}"
        read
    fi
done

# Summary
echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "Total Tests:    ${TOTAL_TESTS}"
echo -e "${GREEN}Passed Tests:   ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed Tests:   ${FAILED_TESTS}${NC}"
echo -e "${YELLOW}Skipped Tests:  ${SKIPPED_TESTS}${NC}"

# Overall result
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed successfully!${NC}"
else
    echo -e "\n${RED}✗ Some tests failed. Check individual results.${NC}"
fi

# List response files
echo -e "\n${BLUE}Response files created:${NC}"
ls -la tc*_response.json 2>/dev/null || echo "No response files found"