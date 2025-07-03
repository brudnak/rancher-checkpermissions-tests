#!/bin/bash
# Setup script for checkPermissions tests

echo "Setting up checkPermissions test environment..."

# Create config.sh if it doesn't exist
if [ ! -f "config.sh" ]; then
    echo "Creating config.sh from template..."
    cp config.sh.template config.sh
    echo "✓ config.sh created"
    echo ""
    echo "Please edit config.sh with your Rancher details:"
    echo "  - RANCHER_URL"
    echo "  - BEARER_TOKEN"
    echo "  - CLUSTER_ID"
else
    echo "✓ config.sh already exists"
fi

# Make all scripts executable
echo ""
echo "Making scripts executable..."
chmod +x *.sh
echo "✓ All scripts are now executable"

# Check for required tools
echo ""
echo "Checking required tools..."
command -v curl >/dev/null 2>&1 || { echo "✗ curl is required but not installed."; exit 1; }
echo "✓ curl is installed"
command -v jq >/dev/null 2>&1 || { echo "✗ jq is required but not installed."; exit 1; }
echo "✓ jq is installed"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit config.sh with your Rancher environment details"
echo "2. Run individual tests: ./tc001_baseline_no_permissions.sh"
echo "3. Or run all tests: ./run_all_tests.sh"
echo ""
echo "To get your cluster ID:"
echo "curl -sk -H \"Authorization: Bearer YOUR_TOKEN\" \\"
echo "  \"https://YOUR_RANCHER_URL/v1/management.cattle.io.clusters\" | jq '.data[].id'"