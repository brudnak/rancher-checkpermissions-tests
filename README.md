# Rancher checkPermissions API Test Suite

Test suite for validating Rancher's checkPermissions query parameter functionality.

## Key Finding

The checkPermissions parameter only works with 3 cluster-scoped resources:
- `management.cattle.io.projects`
- `management.cattle.io.clusterroletemplatebindings`
- `management.cattle.io.nodes`

Plus project-level permissions for `management.cattle.io.projectroletemplatebindings`.

## Quick Start

1. Clone repo and run setup:
   
   ```shell
   ./setup.sh
   ```

2. Edit config.sh with your Rancher details

3. Run tests:
   
   ```shell
   ./run_all_tests.sh
   ```

## Files

- setup.sh - Initial setup and dependency check
- config.sh.template - Configuration template
- run_all_tests.sh - Run all tests
- tc001-tc011 - Individual test scripts
- cleanup.sh - Clean up test artifacts

## Configuration

Edit config.sh with:
- RANCHER_URL: Your Rancher server URL
- BEARER_TOKEN: Cluster member/owner token
- CLUSTER_ID: Target cluster ID
- PROJECT_ID: Project ID (for project tests)
- PROJECT_OWNER_TOKEN: Project owner token
- PROJECT_MEMBER_TOKEN: Project member token with "Manage Project Members" role

## Requirements

- curl, jq
- Cluster access with appropriate user roles

## Tests

11 tests covering baseline functionality, resource filtering, encoding, project permissions, and access control.

All tests should pass when properly configured.