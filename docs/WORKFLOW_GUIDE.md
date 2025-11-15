# Workflow Guide

## Introduction

This guide explains how to use and customize the n8n Job Hunter workflows. Whether you're new to n8n or an experienced user, this guide will help you get the most out of the system.

## Quick Start

### 1. Import Workflows

```bash
# Run the import script
./scripts/import-workflows.sh

# Or manually:
# 1. Open n8n UI (http://localhost:5678)
# 2. Go to Workflows → Import from File
# 3. Select workflow JSON files from workflows/ directory
```

### 2. Configure Credentials

In the n8n UI, configure these credentials:

#### PostgreSQL Database
1. Go to Credentials → New
2. Select "Postgres"
3. Name: "PostgreSQL Database"
4. Fill in database details from `.env`

#### SMTP (Email)
1. Go to Credentials → New
2. Select "SMTP"
3. Name: "SMTP Account"
4. Fill in SMTP details from `.env`

#### API Credentials
- LinkedIn OAuth2 API
- Indeed Publisher API
- Glassdoor API (if using)

### 3. Update Configuration

Edit `config/settings.json`:

```json
{
  "jobSearch": {
    "keywords": ["your", "keywords"],
    "locations": ["your", "locations"],
    "salaryRange": {
      "min": 80000,
      "max": 180000
    }
  }
}
```

### 4. Activate Workflows

1. Open the **Job Hunter - Main Orchestrator** workflow
2. Click "Active" toggle in the top right
3. The workflow will run automatically every 6 hours

⚠️ **Important**: Only activate the orchestrator workflow. Sub-workflows should remain inactive.

## Workflow Descriptions

### Core Orchestrator

**File**: `workflows/core/job-hunter-orchestrator.json`

**Purpose**: Main coordination workflow

**Schedule**: Every 6 hours (configurable)

**Process**:
1. Loads configuration from `settings.json`
2. Executes all scraper sub-workflows in parallel
3. Merges results from all sources
4. Runs deduplication
5. Enriches job data
6. Stores in database
7. Sends notifications
8. Handles errors

**Configuration**:
- Edit the Schedule Trigger node to change frequency
- Modify the cron expression: `0 */6 * * *`

### LinkedIn Scraper

**File**: `workflows/sub-workflows/linkedin-scraper.json`

**Purpose**: Scrapes job listings from LinkedIn

**Features**:
- OAuth2 authentication
- Rate limiting protection
- Keyword and location filtering
- Experience level filtering
- Remote job detection

**Input Parameters**:
```json
{
  "keywords": "software engineer",
  "location": "remote",
  "experienceLevel": "mid,senior",
  "excludeKeywords": ["unpaid"],
  "minSalary": 80000
}
```

**Output**: Standardized job objects

**Customization**:
- Modify HTTP Request URL for different LinkedIn endpoints
- Adjust filter conditions in "Filter Jobs by Criteria" node
- Change rate limit delay in "Rate Limit Protection" node

### Deduplication Processor

**File**: `workflows/sub-workflows/deduplication.json`

**Purpose**: Removes duplicate job listings

**Strategies**:
1. Exact ID match (source + job ID)
2. URL match (same posting URL)
3. Fuzzy match (similar title + company + location)

**Logic**:
- When duplicates found, keeps the newer posting
- If same date, keeps the entry with more data
- Adds deduplication statistics to output

**Customization**:
- Edit the Code node to modify deduplication strategies
- Add additional matching criteria
- Adjust the priority logic for which duplicate to keep

### Job Enrichment

**File**: `workflows/sub-workflows/job-enrichment.json`

**Purpose**: Adds intelligence to job listings

**Enrichment Features**:
- **Skill Detection**: Extracts technologies from job text
  - Programming languages
  - Frameworks & libraries
  - Databases
  - Cloud platforms
  - Development tools

- **Remote Analysis**: Identifies remote-friendly positions

- **Experience Level**: Estimates seniority from title

- **Relevance Scoring**: Rates job quality (0-100)
  - +5 points per detected skill
  - +20 for salary information
  - +10 for remote-friendly

**Output**: Jobs with enrichment metadata

**Customization**:
- Add more skills to `skillPatterns` object
- Modify scoring algorithm
- Add custom analysis logic
- Change relevance threshold (default: 50)

### Database Storage

**File**: `workflows/sub-workflows/database-storage.json`

**Purpose**: Stores jobs in PostgreSQL database

**Features**:
- Auto-creates schema on first run
- Upserts jobs (insert or update on conflict)
- Composite primary key (source + id) prevents duplicates
- Optimized indexes for search performance
- Full-text search on title and description

**Tables Created**:
- `jobs` - All job listings
- `applications` - Application tracking
- `saved_searches` - Search configurations
- `job_alerts` - Notification history

**Customization**:
- Modify SQL in "Initialize Database Schema" node
- Add custom fields to schema
- Create additional indexes
- Add custom tables

### Notifications

**File**: `workflows/sub-workflows/notifications.json`

**Purpose**: Sends multi-channel job alerts

**Channels**:
- **Email**: Beautiful HTML emails with job details
- **Slack**: Rich message blocks with apply buttons
- **Discord**: Webhook notifications

**Features**:
- Only sends if new jobs found
- Shows top N jobs (configurable)
- Includes summary statistics
- Direct links to apply
- Responsive HTML design

**Customization**:
- Edit HTML template in "Generate Email Content" node
- Modify Slack blocks in "Generate Slack Message" node
- Change number of jobs shown (default: 10 for email, 5 for Slack)
- Add additional notification channels

## Common Customizations

### Change Scraping Schedule

Edit the Schedule Trigger node in the orchestrator:

```javascript
// Every 6 hours (default)
"0 */6 * * *"

// Every 3 hours
"0 */3 * * *"

// Every day at 9 AM
"0 9 * * *"

// Every Monday at 9 AM
"0 9 * * MON"
```

### Add Custom Job Filters

In any scraper workflow, add an IF node after transformation:

```javascript
// Filter by keyword in title
{{ $json.title.toLowerCase().includes('senior') }}

// Filter by salary minimum
{{ $json.salary?.min >= 100000 }}

// Filter by location
{{ ['remote', 'san francisco'].includes($json.location.toLowerCase()) }}

// Exclude companies
{{ !['company1', 'company2'].includes($json.company.toLowerCase()) }}
```

### Customize Enrichment Logic

Edit the Code node in `job-enrichment.json`:

```javascript
// Add new skill categories
const skillPatterns = {
  languages: [...],
  frameworks: [...],
  databases: [...],
  // Add your custom category
  security: ['owasp', 'penetration testing', 'cybersecurity']
};

// Modify scoring
const relevanceScore =
  skillCount * 5 +
  (job.salary ? 20 : 0) +
  (isRemoteFriendly ? 10 : 0) +
  (isTopCompany ? 15 : 0); // Add custom factor
```

### Add New Job Platform

1. **Create New Scraper Workflow**:
   ```json
   {
     "name": "Job Scraper - YourPlatform",
     "nodes": [
       { "type": "n8n-nodes-base.executeWorkflowTrigger" },
       { "type": "n8n-nodes-base.httpRequest" },
       { "type": "n8n-nodes-base.code" }
     ]
   }
   ```

2. **Add HTTP Request Node**:
   - Configure API endpoint
   - Add authentication
   - Set query parameters

3. **Add Transformation Code**:
   ```javascript
   // Transform to standard format
   return jobs.map(job => ({
     json: {
       id: job.uniqueId,
       source: 'yourplatform',
       title: job.jobTitle,
       company: job.companyName,
       // ... map all fields
     }
   }));
   ```

4. **Add to Orchestrator**:
   - Add Execute Workflow node
   - Connect to Merge node
   - Update configuration

## Troubleshooting

### Workflow Not Running

**Check**:
- Is the orchestrator workflow activated?
- Is the schedule correct?
- Check n8n execution logs

**Fix**:
- Click "Execute Workflow" manually to test
- Check error messages in execution log
- Verify credentials are configured

### No Jobs Appearing

**Check**:
- Are the API credentials valid?
- Is the search criteria too restrictive?
- Check the workflow execution logs

**Fix**:
- Test API credentials manually
- Broaden search keywords
- Lower salary minimum
- Check rate limiting

### Database Errors

**Check**:
- Is PostgreSQL running?
- Are database credentials correct?
- Does the database exist?

**Fix**:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Run database setup
./scripts/setup-database.sh

# Test connection
psql -h localhost -U n8n_user -d n8n_job_hunter
```

### Notifications Not Sending

**Check**:
- Are notification channels enabled in settings?
- Are SMTP/webhook credentials configured?
- Did any new jobs get added?

**Fix**:
- Verify settings.json configuration
- Test SMTP connection manually
- Check workflow execution for errors
- Verify "Check for New Jobs" condition

## Best Practices

### Development

1. **Test in Isolation**: Test each sub-workflow independently
2. **Use Manual Execution**: Debug with manual runs before activating
3. **Add Sticky Notes**: Document complex logic
4. **Version Control**: Commit workflow changes regularly

### Production

1. **Monitor Executions**: Check n8n execution history regularly
2. **Set Up Alerts**: Configure error notifications
3. **Review Logs**: Check for API errors or rate limiting
4. **Clean Old Data**: Periodically remove old job listings

### Performance

1. **Limit Batch Size**: Don't scrape too many jobs at once
2. **Respect Rate Limits**: Configure appropriate delays
3. **Index Database**: Keep database indexes up to date
4. **Monitor Resources**: Watch n8n memory usage

## Advanced Topics

### Parallel Execution

Run multiple scrapers simultaneously:

```javascript
// In orchestrator, all Execute Workflow nodes
// connected to same input will run in parallel
```

### Conditional Workflows

Execute workflows based on conditions:

```javascript
// Use IF node before Execute Workflow
{{ $json.platform === 'linkedin' ? 'linkedin-scraper' : 'indeed-scraper' }}
```

### Data Transformation

Advanced data manipulation:

```javascript
// In Code node
const transformed = $input.all().map(item => ({
  json: {
    ...item.json,
    // Custom transformations
    fullTitle: `${item.json.title} at ${item.json.company}`,
    keywords: extractKeywords(item.json.description),
    score: calculateScore(item.json)
  }
}));
```

### Error Recovery

Implement retry logic:

```javascript
// In Error Workflow node
const retryCount = $execution.data.retry || 0;
if (retryCount < 3) {
  // Wait and retry
  await sleep(Math.pow(2, retryCount) * 1000);
  return { retry: retryCount + 1 };
}
```

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [Workflow Examples](https://n8n.io/workflows/)
- [n8n Best Practices](https://docs.n8n.io/workflows/best-practices/)

## Getting Help

If you encounter issues:

1. Check the execution logs in n8n UI
2. Review this guide and architecture documentation
3. Search n8n community forum
4. Create an issue in the GitHub repository
