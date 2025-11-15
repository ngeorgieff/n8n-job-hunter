#!/bin/bash

# n8n Job Hunter - Export Workflows Script
# Exports workflows from n8n to the workflows directory

set -e

echo "========================================="
echo "n8n Job Hunter - Export Workflows"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get n8n user folder
N8N_FOLDER="${N8N_USER_FOLDER:-$HOME/.n8n}"
WORKFLOWS_SOURCE="$N8N_FOLDER/workflows"

echo "n8n folder: $N8N_FOLDER"
echo "Workflows source: $WORKFLOWS_SOURCE"
echo ""

if [ ! -d "$WORKFLOWS_SOURCE" ]; then
    echo -e "${RED}✗ n8n workflows directory not found: $WORKFLOWS_SOURCE${NC}"
    echo "Make sure n8n is installed and has been run at least once."
    exit 1
fi

# Check if there are any workflows to export
WORKFLOW_COUNT=$(find "$WORKFLOWS_SOURCE" -name "*.json" | wc -l)
if [ "$WORKFLOW_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No workflows found in: $WORKFLOWS_SOURCE${NC}"
    echo "Create some workflows in n8n first, then run this script."
    exit 0
fi

echo -e "${GREEN}Found $WORKFLOW_COUNT workflow(s) to export${NC}"
echo ""

# Create backup directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups/workflows_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "Exporting workflows..."
echo ""

# Export all workflows
for workflow in "$WORKFLOWS_SOURCE"/*.json; do
    if [ -f "$workflow" ]; then
        filename=$(basename "$workflow")
        cp "$workflow" "$BACKUP_DIR/$filename"
        echo "  ✓ Exported: $filename"
    fi
done

echo ""
echo "========================================="
echo -e "${GREEN}Export Complete!${NC}"
echo "========================================="
echo ""
echo "Workflows exported to: $BACKUP_DIR"
echo ""
echo "To organize these workflows:"
echo "1. Review the exported files in: $BACKUP_DIR"
echo "2. Move core orchestrator workflows to: workflows/core/"
echo "3. Move reusable sub-workflows to: workflows/sub-workflows/"
echo "4. Move job-specific workflows to: workflows/jobs/"
echo ""
