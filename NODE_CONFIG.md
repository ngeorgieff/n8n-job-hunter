# Node Configuration Reference

This document provides detailed configuration information for each node in the n8n Job Hunter workflow.

## Table of Contents

1. [Trigger Nodes](#trigger-nodes)
2. [Parameter Nodes](#parameter-nodes)
3. [Job Search Nodes](#job-search-nodes)
4. [Processing Nodes](#processing-nodes)
5. [Storage Nodes](#storage-nodes)
6. [AI Nodes](#ai-nodes)
7. [Notification Nodes](#notification-nodes)

---

## Trigger Nodes

### Schedule Trigger

**Purpose**: Automatically runs the workflow on a daily schedule

**Node Type**: `n8n-nodes-base.scheduleTrigger`

**Configuration**:
```json
{
  "rule": {
    "interval": [
      {
        "field": "days",
        "daysInterval": 1
      }
    ]
  }
}
```

**Customization Options**:

| Interval Type | Configuration Example | Description |
|--------------|----------------------|-------------|
| Every N hours | `{"field": "hours", "hoursInterval": 12}` | Run every 12 hours |
| Every N days | `{"field": "days", "daysInterval": 1}` | Run daily (default) |
| Weekly | `{"field": "days", "daysInterval": 7}` | Run weekly |
| Custom cron | `{"field": "cronExpression", "expression": "0 9 * * *"}` | Run at 9 AM daily |

**Best Practices**:
- For most users, daily execution is optimal
- Avoid running more than twice daily to prevent API rate limits
- Consider your timezone when setting up cron expressions

---

## Parameter Nodes

### Set Job Parameters

**Purpose**: Defines search criteria for all job platforms

**Node Type**: `n8n-nodes-base.set`

**Configuration**:
```json
{
  "values": {
    "string": [
      {
        "name": "keyword",
        "value": "software engineer"
      },
      {
        "name": "location",
        "value": "San Francisco, CA"
      },
      {
        "name": "country",
        "value": "us"
      },
      {
        "name": "maxResults",
        "value": "50"
      }
    ]
  }
}
```

**Parameter Details**:

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| keyword | String | "software engineer" | Job title or keywords to search |
| location | String | "San Francisco, CA" | Geographic location (city, state) |
| country | String | "us" | ISO country code for Adzuna API |
| maxResults | String | "50" | Maximum results per platform |

**Country Codes** (for Adzuna):
- `us` - United States
- `gb` - United Kingdom
- `ca` - Canada
- `au` - Australia
- `de` - Germany
- `fr` - France
- See [Adzuna API docs](https://developer.adzuna.com/docs/search) for full list

**Tips**:
- Use specific job titles for better results (e.g., "Senior React Developer" vs "developer")
- Include relevant keywords (e.g., "remote software engineer")
- Start with maxResults of 20-30 for testing
- Location format varies by platform; "City, State" works best

---

## Job Search Nodes

### Apify LinkedIn Jobs

**Purpose**: Searches LinkedIn using Apify's LinkedIn Jobs Scraper

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "POST",
  "url": "https://api.apify.com/v2/acts/apify~linkedin-jobs-scraper/runs",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      {"name": "token", "value": "={{$credentials.apifyApi.apiKey}}"}
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {"name": "searchKeyword", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
      {"name": "location", "value": "={{$node['Set Job Parameters'].json['location']}}"},
      {"name": "maxItems", "value": "={{$node['Set Job Parameters'].json['maxResults']}}"}
    ]
  }
}
```

**Credential Setup**:
- Type: HTTP Header Auth
- Header Name: `Authorization`
- Header Value: `Bearer YOUR_APIFY_API_TOKEN`

**Additional Parameters** (optional):
```json
{
  "datePosted": "past-week",     // Filter by posting date
  "experienceLevel": ["entry"],  // Experience level filter
  "jobType": ["full-time"],      // Job type filter
  "remote": true                 // Remote jobs only
}
```

**Rate Limits**: Apify free tier allows ~100 runs/month

---

### Apify Indeed Jobs

**Purpose**: Searches Indeed using Apify's Indeed Scraper

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "POST",
  "url": "https://api.apify.com/v2/acts/apify~indeed-scraper/runs",
  "bodyParameters": {
    "parameters": [
      {"name": "queries", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
      {"name": "location", "value": "={{$node['Set Job Parameters'].json['location']}}"},
      {"name": "maxItems", "value": "={{$node['Set Job Parameters'].json['maxResults']}}"}
    ]
  }
}
```

**Additional Filters**:
```json
{
  "fromage": 7,           // Jobs posted in last N days
  "radius": 25,           // Search radius in miles
  "jobType": "fulltime"   // Job type filter
}
```

---

### Apify Glassdoor Jobs

**Purpose**: Searches Glassdoor using Apify's Glassdoor Scraper

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "POST",
  "url": "https://api.apify.com/v2/acts/apify~glassdoor-scraper/runs",
  "bodyParameters": {
    "parameters": [
      {"name": "searches", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
      {"name": "location", "value": "={{$node['Set Job Parameters'].json['location']}}"},
      {"name": "maxItems", "value": "={{$node['Set Job Parameters'].json['maxResults']}}"}
    ]
  }
}
```

**Note**: Glassdoor scraping may be slower than other platforms

---

### Apify Upwork Jobs

**Purpose**: Searches Upwork using Apify's Upwork Jobs Scraper

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "POST",
  "url": "https://api.apify.com/v2/acts/apify~upwork-jobs-scraper/runs",
  "bodyParameters": {
    "parameters": [
      {"name": "searchTerm", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
      {"name": "maxItems", "value": "={{$node['Set Job Parameters'].json['maxResults']}}"}
    ]
  }
}
```

**Note**: Upwork doesn't use location parameter (global freelance platform)

---

### Adzuna API Jobs

**Purpose**: Searches jobs using Adzuna's official API

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "GET",
  "url": "https://api.adzuna.com/v1/api/jobs/{{$node['Set Job Parameters'].json['country']}}/search/1",
  "queryParameters": {
    "parameters": [
      {"name": "app_id", "value": "={{$credentials.adzunaApi.appId}}"},
      {"name": "app_key", "value": "={{$credentials.adzunaApi.appKey}}"},
      {"name": "what", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
      {"name": "where", "value": "={{$node['Set Job Parameters'].json['location']}}"},
      {"name": "results_per_page", "value": "={{$node['Set Job Parameters'].json['maxResults']}}"}
    ]
  }
}
```

**Additional Parameters**:
```json
{
  "salary_min": 50000,          // Minimum salary filter
  "salary_max": 150000,         // Maximum salary filter
  "full_time": 1,               // Full-time jobs only
  "permanent": 1,               // Permanent positions only
  "sort_by": "date"             // Sort by date or relevance
}
```

**Rate Limits**: Free tier allows 1,000 calls/month

---

## Processing Nodes

### Wait for Apify Results

**Purpose**: Waits for Apify scraping jobs to complete and fetches results

**Node Type**: `n8n-nodes-base.code`

**Key Logic**:
```javascript
// Polls Apify API every 10 seconds for up to 5 minutes
// Fetches dataset when status is 'SUCCEEDED'
const maxAttempts = 30;
const waitTime = 10000; // 10 seconds
```

**Customization**:
```javascript
// Increase wait time for slower scrapers
const waitTime = 15000; // 15 seconds

// Increase max attempts for larger datasets
const maxAttempts = 60; // Wait up to 10 minutes
```

**Error Handling**:
- Returns empty array if run fails
- Logs errors to console
- Continues workflow even if some sources fail

---

### Process Adzuna Results

**Purpose**: Normalizes Adzuna API response format

**Node Type**: `n8n-nodes-base.code`

**Normalization**:
```javascript
// Converts Adzuna format to standard format
{
  title: job.title,
  company: job.company.display_name,
  location: job.location.display_name,
  description: job.description,
  url: job.redirect_url,
  salary_min: job.salary_min,
  salary_max: job.salary_max,
  created: job.created,
  source: 'Adzuna'
}
```

---

### Normalize Job Data

**Purpose**: Standardizes job data from all sources

**Node Type**: `n8n-nodes-base.code`

**Field Mapping**:
```javascript
{
  title: job.title || job.jobTitle || job.position,
  company: job.company || job.companyName || job.employer,
  location: job.location || job.jobLocation,
  description: job.description || job.jobDescription || job.summary,
  url: job.url || job.link || job.jobUrl,
  salary: job.salary || `${job.salary_min}-${job.salary_max}`,
  posted_date: job.created || job.postedAt || job.datePosted,
  source: job.source,
  uniqueId: `${title}-${company}-${location}`.toLowerCase()
}
```

---

### Deduplicate Jobs

**Purpose**: Removes duplicate job postings

**Node Type**: `n8n-nodes-base.code`

**Deduplication Logic**:
```javascript
// Uses Set to track unique IDs
const uniqueId = `${job.title}-${job.company}-${job.location}`
  .toLowerCase()
  .replace(/\s+/g, '-');
```

**Customization**:
```javascript
// More aggressive deduplication (title + company only)
const uniqueId = `${job.title}-${job.company}`.toLowerCase();

// Less aggressive (include description hash)
const uniqueId = `${job.title}-${job.company}-${hashDescription(job.description)}`;
```

---

## Storage Nodes

### Save to Google Sheets

**Purpose**: Saves job listings to Google Sheets

**Node Type**: `n8n-nodes-base.googleSheets`

**Configuration**:
```json
{
  "operation": "appendOrUpdate",
  "documentId": "={{$env.GOOGLE_SHEET_ID}}",
  "sheetName": "Jobs",
  "columns": {
    "Title": "={{$json.title}}",
    "Company": "={{$json.company}}",
    "Location": "={{$json.location}}",
    "Description": "={{$json.description}}",
    "URL": "={{$json.url}}",
    "Salary": "={{$json.salary}}",
    "Posted Date": "={{$json.posted_date}}",
    "Source": "={{$json.source}}",
    "Status": "New",
    "Applied": "No",
    "Date Found": "={{new Date().toISOString()}}"
  }
}
```

**Sheet Setup Requirements**:
- Sheet name must be exactly "Jobs"
- Columns must match the configuration
- First row should contain headers

**Tips**:
- Use "appendOrUpdate" to avoid duplicates
- Add conditional formatting in Google Sheets for better visualization
- Create multiple sheets for different job types

---

### Update Sheet with AI Content

**Purpose**: Updates Google Sheets with AI-generated resumes and cover letters

**Node Type**: `n8n-nodes-base.googleSheets`

**Configuration**:
```json
{
  "operation": "update",
  "columns": {
    "Tailored Resume": "={{$json.tailored_resume}}",
    "Cover Letter": "={{$json.cover_letter}}",
    "AI Processed": "={{$json.ai_processed ? 'Yes' : 'No'}}"
  }
}
```

---

## AI Nodes

### Load User Documents

**Purpose**: Loads resume and cover letter templates from environment

**Node Type**: `n8n-nodes-base.set`

**Configuration**:
```json
{
  "assignments": [
    {
      "name": "user_resume",
      "value": "={{$env.USER_RESUME_TEXT}}"
    },
    {
      "name": "user_cover_letter_template",
      "value": "={{$env.USER_COVER_LETTER_TEMPLATE}}"
    }
  ]
}
```

**Alternative**: Load from files
```javascript
// In a Code node
const fs = require('fs');
const resume = fs.readFileSync('/path/to/resume.txt', 'utf8');
const coverLetter = fs.readFileSync('/path/to/cover-letter.txt', 'utf8');
```

---

### OpenRouter AI - Tailor Documents

**Purpose**: Uses AI to customize resume and cover letter for each job

**Node Type**: `n8n-nodes-base.httpRequest`

**Configuration**:
```json
{
  "method": "POST",
  "url": "https://openrouter.ai/api/v1/chat/completions",
  "headers": {
    "Authorization": "Bearer {{$credentials.openRouterApi.apiKey}}",
    "HTTP-Referer": "https://n8n-job-hunter.local",
    "X-Title": "n8n Job Hunter"
  },
  "body": {
    "model": "openai/gpt-4-turbo",
    "messages": [
      {
        "role": "system",
        "content": "You are a professional resume and cover letter writer..."
      },
      {
        "role": "user",
        "content": "Job Title: {{$json.title}}..."
      }
    ],
    "temperature": 0.7,
    "max_tokens": 2000
  }
}
```

**Model Options**:

| Model | Cost per 1K tokens | Quality | Speed |
|-------|-------------------|---------|-------|
| openai/gpt-4-turbo | $0.01 / $0.03 | Excellent | Fast |
| openai/gpt-3.5-turbo | $0.0005 / $0.0015 | Good | Very Fast |
| anthropic/claude-2 | $0.008 / $0.024 | Excellent | Fast |
| google/palm-2 | $0.00025 / $0.0005 | Good | Fast |

**Prompt Customization**:
```javascript
// More detailed instructions
"content": "You are an expert resume writer with 10+ years of experience. Analyze the job description and tailor the resume to highlight the most relevant experience. Focus on quantifiable achievements and use action verbs. Keep the resume to 2 pages maximum."

// Industry-specific
"content": "You are a resume writer specializing in tech/software engineering positions. Use industry-standard terminology and highlight technical skills, projects, and achievements."
```

---

### Process AI Response

**Purpose**: Extracts AI-generated content from API response

**Node Type**: `n8n-nodes-base.code`

**Error Handling**:
```javascript
try {
  const aiResponse = JSON.parse(job.choices[0].message.content);
  // Process successful response
} catch (error) {
  // Keep original job data if AI processing fails
  return {
    ...job,
    ai_processed: false,
    ai_error: error.message
  };
}
```

---

## Notification Nodes

### Prepare Email Summary

**Purpose**: Creates HTML email with job summary

**Node Type**: `n8n-nodes-base.code`

**Email Template Sections**:
1. Header with total jobs found
2. Breakdown by source
3. Top 10 job listings with details
4. Link to Google Sheet

**Customization**:
```javascript
// Change number of jobs in email
jobs.slice(0, 20) // Show top 20 instead of 10

// Add filtering for email
const topJobs = jobs.filter(job => 
  job.salary && parseInt(job.salary) > 100000
);

// Group by different criteria
const jobsByLocation = groupBy(jobs, 'location');
```

**HTML Styling**:
```javascript
// Customize colors and styling
emailBody += `<div style="
  background-color: #f5f5f5;
  padding: 20px;
  border-left: 4px solid #4CAF50;
  margin-bottom: 15px;
">`;
```

---

### Send Gmail Summary

**Purpose**: Sends email summary via Gmail

**Node Type**: `n8n-nodes-base.gmail`

**Configuration**:
```json
{
  "sendTo": "={{$env.RECIPIENT_EMAIL}}",
  "subject": "={{$json.subject}}",
  "emailType": "html",
  "message": "={{$json.body}}"
}
```

**Advanced Options**:
```json
{
  "ccEmail": "backup@email.com",     // CC recipients
  "bccEmail": "archive@email.com",   // BCC recipients
  "attachments": "sheet",            // Attach exported sheet
  "senderName": "Job Hunter Bot"     // Custom sender name
}
```

**Multiple Recipients**:
```javascript
// In Prepare Email Summary node
const recipients = [
  process.env.RECIPIENT_EMAIL,
  "spouse@email.com",
  "career-coach@email.com"
].join(',');
```

---

## Workflow Optimization Tips

### Performance

1. **Parallel Processing**: Already configured - all job searches run in parallel
2. **Batch AI Processing**: Process multiple jobs in single API call to reduce costs
3. **Caching**: Add caching to avoid re-processing same jobs

### Cost Reduction

1. **Limit AI Processing**: Only process top N jobs
2. **Use Cheaper Models**: Switch to gpt-3.5-turbo for initial testing
3. **Reduce Frequency**: Run weekly instead of daily

### Result Quality

1. **Better Filtering**: Add salary, location, or keyword filters
2. **Scoring System**: Rank jobs by relevance
3. **Custom Alerts**: Send immediate notification for high-priority jobs

---

## Troubleshooting

### Node Execution Errors

**Apify Nodes Timeout**:
- Increase `maxAttempts` in "Wait for Apify Results"
- Check Apify dashboard for failed runs
- Verify API credentials

**Google Sheets Fails**:
- Reconnect OAuth credentials
- Verify sheet name is exactly "Jobs"
- Check column names match configuration

**AI Node Errors**:
- Verify OpenRouter API key
- Check credit balance
- Test with smaller input
- Try different model

**Email Not Sending**:
- Verify Gmail OAuth credentials
- Check if Gmail API is enabled
- Ensure recipient email is valid

---

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Apify Documentation](https://docs.apify.com/)
- [Adzuna API Reference](https://developer.adzuna.com/docs)
- [OpenRouter Models](https://openrouter.ai/models)
- [Google Sheets API](https://developers.google.com/sheets/api)
