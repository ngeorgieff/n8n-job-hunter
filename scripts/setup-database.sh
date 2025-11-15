#!/bin/bash

# n8n Job Hunter - Database Setup Script
# Creates PostgreSQL database and tables for job tracking

set -e

echo "========================================="
echo "n8n Job Hunter - Database Setup"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}✗ .env file not found${NC}"
    echo "Please run ./scripts/setup.sh first"
    exit 1
fi

# Database configuration
DB_NAME="${DB_DATABASE:-n8n_job_hunter}"
DB_USER="${DB_USER:-n8n_user}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

echo "Database Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Check if PostgreSQL is running
if ! command -v psql &> /dev/null; then
    echo -e "${RED}✗ PostgreSQL is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating database and user...${NC}"
echo "(You may be prompted for your PostgreSQL password)"
echo ""

# Create database and user
psql -h "$DB_HOST" -p "$DB_PORT" -U postgres << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

echo -e "${GREEN}✓ Database and user created${NC}"
echo ""

echo -e "${YELLOW}Creating tables and indexes...${NC}"

# Create tables
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- Create jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id VARCHAR(255) NOT NULL,
    source VARCHAR(50) NOT NULL,
    title VARCHAR(500) NOT NULL,
    company VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    description TEXT,
    salary_min INTEGER,
    salary_max INTEGER,
    url TEXT NOT NULL,
    posted_date TIMESTAMP,
    job_type VARCHAR(50),
    experience_level VARCHAR(50),
    scraped_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    PRIMARY KEY (source, id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs(posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company);
CREATE INDEX IF NOT EXISTS idx_jobs_location ON jobs(location);
CREATE INDEX IF NOT EXISTS idx_jobs_scraped_at ON jobs(scraped_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_title ON jobs USING GIN(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_jobs_description ON jobs USING GIN(to_tsvector('english', description));
CREATE INDEX IF NOT EXISTS idx_jobs_metadata ON jobs USING GIN(metadata);

-- Create applications tracking table
CREATE TABLE IF NOT EXISTS applications (
    id SERIAL PRIMARY KEY,
    job_source VARCHAR(50) NOT NULL,
    job_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    resume_version VARCHAR(100),
    cover_letter TEXT,
    FOREIGN KEY (job_source, job_id) REFERENCES jobs(source, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at ON applications(applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_job ON applications(job_source, job_id);

-- Create saved searches table
CREATE TABLE IF NOT EXISTS saved_searches (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    keywords TEXT[],
    locations TEXT[],
    min_salary INTEGER,
    max_salary INTEGER,
    job_types TEXT[],
    experience_levels TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_run TIMESTAMP
);

-- Create job alerts table
CREATE TABLE IF NOT EXISTS job_alerts (
    id SERIAL PRIMARY KEY,
    job_source VARCHAR(50) NOT NULL,
    job_id VARCHAR(255) NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    channel VARCHAR(50),
    FOREIGN KEY (job_source, job_id) REFERENCES jobs(source, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_job_alerts_sent_at ON job_alerts(sent_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
CREATE TRIGGER update_applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
EOF

echo -e "${GREEN}✓ Tables and indexes created${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}Database Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Database structure:"
echo "  • jobs - Stores all job listings"
echo "  • applications - Tracks your applications"
echo "  • saved_searches - Stores search configurations"
echo "  • job_alerts - Tracks sent notifications"
echo ""
echo "You can now use this database with n8n workflows."
echo ""
