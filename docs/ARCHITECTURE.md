# Architecture Documentation

## Overview

The n8n Job Hunter is built with a modular architecture that follows n8n best practices for 2025. This document describes the system architecture, design decisions, and workflow organization.

## Design Principles

### 1. Modular Design
- **Separation of Concerns**: Each workflow handles a single responsibility
- **Reusability**: Sub-workflows can be used across multiple parent workflows
- **Independent Testing**: Each module can be developed and tested independently
- **Easy Updates**: Changes to one module don't affect others

### 2. Scalability
- **Horizontal Scaling**: Add more scrapers without changing core logic
- **Rate Limiting**: Built-in protection against API throttling
- **Batch Processing**: Efficient handling of large job datasets
- **Database Optimization**: Indexed queries and efficient storage

### 3. Reliability
- **Error Handling**: Comprehensive error catching and retry logic
- **Data Validation**: Input/output validation at each step
- **Deduplication**: Multiple strategies to prevent duplicate entries
- **Audit Trail**: Complete logging of all operations

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Orchestrator Workflow                     │
│                  (job-hunter-orchestrator)                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├──► Schedule Trigger (Every 6 hours)
                  │
                  ├──► Load Configuration
                  │
                  v
┌─────────────────────────────────────────────────────────────┐
│                   Parallel Scraping Phase                    │
├─────────────────┬─────────────────┬─────────────────────────┤
│  LinkedIn       │    Indeed       │   Remote Job Boards     │
│  Scraper        │    Scraper      │   Scraper               │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         │                 │                 │
         └─────────────────┴─────────────────┘
                           │
                           v
┌─────────────────────────────────────────────────────────────┐
│                    Data Processing Phase                     │
├─────────────────┬─────────────────┬─────────────────────────┤
│  Merge Results  │  Deduplication  │  Job Enrichment         │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         └─────────────────┴─────────────────┘
                           │
                           v
┌─────────────────────────────────────────────────────────────┐
│                   Storage & Notification                     │
├─────────────────┬───────────────────────────────────────────┤
│  Database       │        Multi-Channel Notifications        │
│  Storage        │    (Email, Slack, Discord)                │
└─────────────────┴───────────────────────────────────────────┘
```

## Workflow Organization

### Core Workflows (`workflows/core/`)
**Purpose**: Main orchestration and coordination

- `job-hunter-orchestrator.json`
  - Coordinates all sub-workflows
  - Manages execution flow
  - Handles scheduling
  - Aggregates results

### Sub-Workflows (`workflows/sub-workflows/`)
**Purpose**: Reusable, single-purpose modules

#### Scraping Modules
- `linkedin-scraper.json` - LinkedIn API integration
- `indeed-scraper.json` - Indeed API integration (to be implemented)
- `remote-jobs-scraper.json` - Remote job boards (to be implemented)

**Features**:
- Rate limiting protection
- Error handling with retries
- Data transformation to standard format
- Filtering by search criteria

#### Processing Modules
- `deduplication.json` - Remove duplicate job listings
  - Multiple deduplication strategies
  - Keeps newest/richest data
  - Provides statistics

- `job-enrichment.json` - Enhance job data
  - Skill extraction
  - Remote work analysis
  - Experience level estimation
  - Relevance scoring

#### Storage Module
- `database-storage.json` - Database operations
  - Schema auto-creation
  - Upsert operations (insert/update)
  - Optimized indexes
  - Full-text search support

#### Notification Module
- `notifications.json` - Multi-channel alerts
  - Email (HTML formatted)
  - Slack (rich blocks)
  - Discord webhooks
  - Conditional sending

## Data Flow

### 1. Job Data Model

```json
{
  "id": "unique-job-id",
  "source": "linkedin|indeed|remote",
  "title": "Software Engineer",
  "company": "Example Corp",
  "location": "Remote",
  "description": "Full job description...",
  "salary": {
    "min": 100000,
    "max": 150000,
    "currency": "USD"
  },
  "url": "https://...",
  "postedDate": "2025-01-15T00:00:00Z",
  "jobType": "full-time|contract|remote",
  "experienceLevel": "senior|mid|junior",
  "scrapedAt": "2025-01-15T12:00:00Z",
  "metadata": {
    "applicationsCount": 50,
    "viewsCount": 200,
    "sponsored": false
  },
  "enrichment": {
    "detectedSkills": {
      "languages": ["javascript", "python"],
      "frameworks": ["react", "node.js"],
      "databases": ["postgresql"],
      "cloud": ["aws"],
      "tools": ["git", "docker"]
    },
    "skillCount": 7,
    "isRemoteFriendly": true,
    "estimatedLevel": "senior",
    "relevanceScore": 85
  }
}
```

### 2. Processing Pipeline

```
Raw Job Data
    ↓
[Scraper] → Transform to standard format
    ↓
[Filter] → Apply search criteria
    ↓
[Merge] → Combine from all sources
    ↓
[Deduplicate] → Remove duplicates
    ↓
[Enrich] → Add intelligence & scoring
    ↓
[Store] → Save to database
    ↓
[Notify] → Send alerts for new jobs
```

## Configuration Management

### Settings (`config/settings.json`)
- Job search criteria
- Platform configurations
- Rate limits
- Notification preferences
- Scheduling

### Credentials (`config/credentials.json`)
- API keys (LinkedIn, Indeed, etc.)
- Database connection
- SMTP settings
- Webhook URLs

### Environment Variables (`.env`)
- n8n configuration
- Paths and ports
- Database connection
- Email settings

## Database Schema

### Tables

#### jobs
Primary storage for all job listings

```sql
CREATE TABLE jobs (
    id VARCHAR(255),
    source VARCHAR(50),
    title VARCHAR(500),
    company VARCHAR(255),
    location VARCHAR(255),
    description TEXT,
    salary_min INTEGER,
    salary_max INTEGER,
    url TEXT,
    posted_date TIMESTAMP,
    job_type VARCHAR(50),
    experience_level VARCHAR(50),
    scraped_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    metadata JSONB,
    PRIMARY KEY (source, id)
);
```

#### applications
Tracks application status

```sql
CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    job_source VARCHAR(50),
    job_id VARCHAR(255),
    status VARCHAR(50),
    applied_at TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (job_source, job_id) REFERENCES jobs(source, id)
);
```

## Error Handling Strategy

### 1. Scraper Errors
- **Rate Limiting (429)**: Wait and retry with exponential backoff
- **Authentication (401)**: Alert user, skip source
- **Network Errors**: Retry up to 3 times
- **Parse Errors**: Log and continue with next item

### 2. Processing Errors
- **Invalid Data**: Filter out, log for review
- **Transformation Errors**: Use defaults, flag for review

### 3. Storage Errors
- **Connection Errors**: Retry with backoff
- **Constraint Violations**: Update existing record
- **Transaction Errors**: Rollback and retry

### 4. Notification Errors
- **Delivery Failures**: Log but don't block pipeline
- **Invalid Recipients**: Alert admin

## Performance Optimizations

### 1. Parallel Execution
- All scrapers run in parallel
- Notifications sent concurrently

### 2. Database Indexing
- Posted date (DESC) - recent jobs
- Company, location - filtering
- Full-text search on title/description

### 3. Rate Limiting
- Configurable per platform
- Automatic backoff on throttling
- Request queuing

### 4. Caching
- Configuration loaded once
- Credentials cached in n8n

## Security Considerations

### 1. Credentials Management
- Stored in n8n credential system
- Never committed to version control
- Environment-specific configurations

### 2. API Security
- Rate limiting to prevent abuse
- Authentication for all external APIs
- Webhook signature verification

### 3. Data Privacy
- No PII stored unless explicitly needed
- Secure database connections
- Encrypted credentials

## Monitoring & Observability

### 1. Execution Logs
- n8n built-in execution history
- Error tracking and alerting
- Performance metrics

### 2. Data Quality
- Deduplication statistics
- Scraping success rates
- Enrichment coverage

### 3. Alerts
- Failed workflow executions
- API quota warnings
- Database connection issues

## Extension Points

### Adding New Job Platforms
1. Create new scraper sub-workflow
2. Transform data to standard format
3. Add to orchestrator workflow
4. Update configuration

### Custom Processing
1. Create new sub-workflow
2. Insert in processing pipeline
3. Update data model if needed

### Additional Notification Channels
1. Add channel logic to notifications workflow
2. Update configuration
3. Add credentials

## Best Practices

### Workflow Development
- ✅ Use Execute Workflow nodes for modularity
- ✅ Add descriptive Sticky Notes for documentation
- ✅ Implement error handling on all external calls
- ✅ Use Set nodes to add metadata
- ✅ Tag workflows appropriately

### Code Nodes
- ✅ Keep JavaScript code simple and readable
- ✅ Add comments for complex logic
- ✅ Validate input data
- ✅ Return consistent data structures

### Testing
- ✅ Test each sub-workflow independently
- ✅ Use manual execution for debugging
- ✅ Validate with sample data
- ✅ Monitor production executions

## Future Enhancements

- [ ] Machine learning for job relevance
- [ ] Auto-apply functionality
- [ ] Interview tracking
- [ ] Salary analysis and trends
- [ ] Company research integration
- [ ] Resume customization
- [ ] Cover letter generation
- [ ] Application follow-up reminders
