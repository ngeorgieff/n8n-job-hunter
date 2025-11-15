#!/bin/bash

# n8n Job Hunter - Setup Script
# This script sets up the n8n job hunter environment

set -e

echo "========================================="
echo "n8n Job Hunter - Setup Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if n8n is installed
echo "Checking for n8n installation..."
if ! command -v n8n &> /dev/null; then
    echo -e "${YELLOW}n8n is not installed. Installing globally...${NC}"
    npm install -g n8n
else
    echo -e "${GREEN}✓ n8n is already installed${NC}"
fi

# Check n8n version
N8N_VERSION=$(n8n --version 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ n8n version: $N8N_VERSION${NC}"
echo ""

# Create necessary directories
echo "Creating project directories..."
mkdir -p ~/.n8n/workflows
mkdir -p ~/.n8n/config
mkdir -p logs
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Copy configuration files
echo "Setting up configuration..."
if [ ! -f config/credentials.json ]; then
    if [ -f config/credentials.example.json ]; then
        cp config/credentials.example.json config/credentials.json
        echo -e "${YELLOW}⚠ Created config/credentials.json from example${NC}"
        echo -e "${YELLOW}  Please edit config/credentials.json with your actual credentials${NC}"
    else
        echo -e "${RED}✗ config/credentials.example.json not found${NC}"
    fi
else
    echo -e "${GREEN}✓ config/credentials.json already exists${NC}"
fi
echo ""

# Create .env file if it doesn't exist
echo "Setting up environment variables..."
if [ ! -f .env ]; then
    cat > .env << 'EOF'
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme

# n8n Paths
N8N_USER_FOLDER=~/.n8n
N8N_CUSTOM_EXTENSIONS=./custom-nodes

# Database Configuration (for job storage)
DB_TYPE=postgresdb
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=n8n_job_hunter
DB_USER=n8n_user
DB_PASSWORD=changeme

# SMTP Configuration (for email notifications)
SMTP_FROM_EMAIL=your-email@example.com
NOTIFICATION_EMAIL=your-email@example.com

# Webhook URLs (optional)
SLACK_WEBHOOK_URL=
DISCORD_WEBHOOK_URL=

# n8n Settings
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=localhost
WEBHOOK_URL=http://localhost:5678/

# Timezone
GENERIC_TIMEZONE=America/New_York
EOF
    echo -e "${YELLOW}⚠ Created .env file${NC}"
    echo -e "${YELLOW}  Please edit .env with your actual configuration${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi
echo ""

# Check for PostgreSQL
echo "Checking for PostgreSQL..."
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL is installed${NC}"
    echo -e "${YELLOW}  Run ./scripts/setup-database.sh to create the database${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL not found${NC}"
    echo -e "${YELLOW}  You can use SQLite instead, or install PostgreSQL:${NC}"
    echo -e "${YELLOW}  - macOS: brew install postgresql${NC}"
    echo -e "${YELLOW}  - Ubuntu: sudo apt-get install postgresql${NC}"
fi
echo ""

# Check for Node.js version
echo "Checking Node.js version..."
NODE_VERSION=$(node --version)
echo -e "${GREEN}✓ Node.js version: $NODE_VERSION${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Edit config/credentials.json with your API keys"
echo "3. Edit config/settings.json with your job search criteria"
echo "4. Run ./scripts/setup-database.sh to create the database (optional)"
echo "5. Run ./scripts/import-workflows.sh to import workflows to n8n"
echo "6. Start n8n: n8n start"
echo ""
echo "For more information, see README.md"
echo ""
