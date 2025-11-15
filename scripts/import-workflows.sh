#!/bin/bash

# n8n Job Hunter - Import Workflows Script
# This script imports all workflow JSON files into n8n

set -e

echo "========================================="
echo "n8n Job Hunter - Import Workflows"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if n8n is installed
if ! command -v n8n &> /dev/null; then
    echo -e "${RED}✗ n8n is not installed${NC}"
    echo "Please run ./scripts/setup.sh first"
    exit 1
fi

# Get n8n user folder
N8N_FOLDER="${N8N_USER_FOLDER:-$HOME/.n8n}"
WORKFLOWS_DEST="$N8N_FOLDER/workflows"

echo "n8n folder: $N8N_FOLDER"
echo "Workflows destination: $WORKFLOWS_DEST"
echo ""

# Create workflows directory if it doesn't exist
mkdir -p "$WORKFLOWS_DEST"

# Function to import workflows from a directory
import_workflows() {
    local source_dir=$1
    local workflow_type=$2

    if [ ! -d "$source_dir" ]; then
        echo -e "${YELLOW}⚠ Directory not found: $source_dir${NC}"
        return
    fi

    echo -e "${GREEN}Importing $workflow_type workflows...${NC}"

    local count=0
    for workflow in "$source_dir"/*.json; do
        if [ -f "$workflow" ]; then
            local filename=$(basename "$workflow")
            cp "$workflow" "$WORKFLOWS_DEST/$filename"
            echo "  ✓ Imported: $filename"
            ((count++))
        fi
    done

    echo -e "${GREEN}  Total: $count workflows imported${NC}"
    echo ""
}

# Import workflows from different directories
echo "Starting workflow import..."
echo ""

import_workflows "workflows/core" "Core"
import_workflows "workflows/sub-workflows" "Sub-workflow"
import_workflows "workflows/jobs" "Job-specific"

echo "========================================="
echo -e "${GREEN}Import Complete!${NC}"
echo "========================================="
echo ""
echo "Workflows have been copied to: $WORKFLOWS_DEST"
echo ""
echo "Next steps:"
echo "1. Start n8n: n8n start"
echo "2. Open http://localhost:5678 in your browser"
echo "3. Import the workflow JSON files from the n8n interface:"
echo "   - Click on 'Workflows' in the menu"
echo "   - Click 'Import from File'"
echo "   - Select the workflow files from: $WORKFLOWS_DEST"
echo "4. Configure credentials in n8n UI"
echo "5. Activate the workflows"
echo ""
echo "Note: Some workflows are sub-workflows and should not be activated directly."
echo "Only activate the main orchestrator workflow."
echo ""
