# API Configuration Reference

This document provides complete API configuration details for all external services used in the Job Hunt Auto-Pilot workflow.

## Table of Contents
1. [Apify API](#apify-api)
2. [Adzuna API](#adzuna-api)
3. [OpenRouter API](#openrouter-api)
4. [Google Sheets API](#google-sheets-api)
5. [Gmail API](#gmail-api)

---

## Apify API

### Base URL
```
https://api.apify.com/v2
```

### Authentication
- **Method**: Bearer token in Authorization header
- **Header**: `Authorization: Bearer YOUR_APIFY_TOKEN`
- **Get Token**: https://console.apify.com/account/integrations

### Recommended Actors

#### 1. Indeed Scraper
- **Actor ID**: `apify/indeed-scraper`
- **URL**: https://apify.com/apify/indeed-scraper
- **Pricing**: ~$0.25 per 1,000 jobs

**Start Run Endpoint**:
```
POST https://api.apify.com/v2/acts/apify~indeed-scraper/runs
```

**Request Body**:
```json
{
  "queries": "Senior DevOps Engineer",
  "location": "remote",
  "maxConcurrency": 5,
  "maxItems": 50,
  "parseCompanyDetails": false,
  "saveOnlyUniqueItems": true,
  "followApplyRedirects": false
}
```

**Get Results**:
```
GET https://api.apify.com/v2/acts/apify~indeed-scraper/runs/{RUN_ID}/dataset/items?format=json
```

#### 2. LinkedIn Jobs Scraper
- **Actor ID**: `misceres/linkedin-jobs-scraper`
- **URL**: https://apify.com/misceres/linkedin-jobs-scraper
- **Pricing**: ~$0.50 per 1,000 jobs

**Start Run Endpoint**:
```
POST https://api.apify.com/v2/acts/misceres~linkedin-jobs-scraper/runs
```

**Request Body**:
```json
{
  "keywords": "Senior DevOps Engineer",
  "location": "United States",
  "datePosted": "past Week",
  "experienceLevel": ["MID_SENIOR_LEVEL", "DIRECTOR"],
  "jobType": ["FULL_TIME"],
  "remote": true,
  "maxItems": 50
}
```

#### 3. Glassdoor Scraper
- **Actor ID**: `apify/glassdoor-scraper`
- **URL**: https://apify.com/apify/glassdoor-scraper
- **Pricing**: ~$0.30 per 1,000 jobs

**Start Run Endpoint**:
```
POST https://api.apify.com/v2/acts/apify~glassdoor-scraper/runs
```

**Request Body**:
```json
{
  "keyword": "Senior DevOps Engineer",
  "location": "United States",
  "includeJobDescription": true,
  "maxJobs": 50,
  "fromAge": 1
}
```

#### 4. Upwork Jobs Scraper
- **Actor ID**: Search "upwork" on Apify Store
- **Alternative**: `clockworks/upwork-jobs-scraper`
- **Pricing**: Varies by actor

**Start Run Endpoint**:
```
POST https://api.apify.com/v2/acts/{ACTOR_ID}/runs
```

**Request Body**:
```json
{
  "query": "Senior DevOps Engineer",
  "category": "Web, Mobile & Software Dev",
  "jobType": "hourly,fixed",
  "maxItems": 50
}
```

### Common Patterns

**Check Run Status**:
```
GET https://api.apify.com/v2/actor-runs/{RUN_ID}
```

**Response**:
```json
{
  "data": {
    "id": "run123",
    "status": "SUCCEEDED",
    "startedAt": "2025-10-26T10:00:00.000Z",
    "finishedAt": "2025-10-26T10:05:23.000Z"
  }
}
```

**Rate Limits**:
- 200 requests per second
- Based on your plan's compute units

**Error Handling**:
```json
{
  "error": {
    "type": "run-failed",
    "message": "Actor run failed after 5 attempts"
  }
}
```

---

## Adzuna API

### Base URL
```
https://api.adzuna.com/v1/api/jobs/{country}/search/{page}
```

### Authentication
- **Method**: Query parameters
- **Parameters**:
  - `app_id`: Your application ID
  - `app_key`: Your application key
- **Get Credentials**: https://developer.adzuna.com/signup

### Search Jobs Endpoint

**URL Template**:
```
GET https://api.adzuna.com/v1/api/jobs/us/search/1?app_id={APP_ID}&app_key={APP_KEY}&results_per_page=50&what={QUERY}&where={LOCATION}
```

**Full Example**:
```
GET https://api.adzuna.com/v1/api/jobs/us/search/1?app_id=12345678&app_key=abcdef1234567890&results_per_page=50&what=Senior%20DevOps%20Engineer&where=remote
```

**Query Parameters**:
- `app_id` (required): Your application ID
- `app_key` (required): Your application key
- `results_per_page` (optional): Default 10, max 50
- `what` (optional): Job title or keyword
- `where` (optional): Location
- `max_days_old` (optional): Filter by job age (e.g., 7)
- `category` (optional): Job category tag
- `sort_by` (optional): `date`, `relevance`, `salary`

**Response Format**:
```json
{
  "results": [
    {
      "id": "3456789012",
      "title": "Senior DevOps Engineer",
      "company": {
        "display_name": "Example Corp"
      },
      "location": {
        "display_name": "San Francisco, CA"
      },
      "description": "We are seeking...",
      "redirect_url": "https://www.adzuna.com/land/ad/3456789012",
      "salary_min": 150000,
      "salary_max": 180000,
      "salary_is_predicted": 0,
      "created": "2025-10-26T08:30:00Z",
      "contract_type": "permanent"
    }
  ],
  "count": 142,
  "mean": 165000
}
```

**Rate Limits**:
- Free tier: 5,000 calls/month
- Developer tier: 25,000 calls/month ($99/month)

**Error Response**:
```json
{
  "exception": "Invalid app_id or app_key",
  "status_code": 401,
  "display": "Unauthorized"
}
```

---

## OpenRouter API

### Base URL
```
https://openrouter.ai/api/v1
```

### Authentication
- **Method**: Bearer token in Authorization header
- **Header**: `Authorization: Bearer YOUR_OPENROUTER_KEY`
- **Get Key**: https://openrouter.ai/keys

### Chat Completions Endpoint

**URL**:
```
POST https://openrouter.ai/api/v1/chat/completions
```

**Headers**:
```
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
HTTP-Referer: https://your-domain.com (optional)
X-Title: Job Hunt Auto-Pilot (optional)
```

**Request Body**:
```json
{
  "model": "anthropic/claude-3.5-sonnet",
  "messages": [
    {
      "role": "user",
      "content": "You are an application assistant..."
    }
  ],
  "temperature": 0.7,
  "max_tokens": 2000,
  "top_p": 1,
  "frequency_penalty": 0,
  "presence_penalty": 0
}
```

**Supported Models**:
1. `anthropic/claude-3.5-sonnet` (~$3 per 1M input tokens, $15 per 1M output)
2. `openai/gpt-4o-mini` (~$0.15 per 1M input tokens, $0.60 per 1M output)
3. `google/gemini-1.5-pro` (~$1.25 per 1M input tokens, $5 per 1M output)
4. `meta-llama/llama-3.1-70b-instruct` (~$0.50 per 1M tokens)

**Response Format**:
```json
{
  "id": "gen-abc123",
  "model": "anthropic/claude-3.5-sonnet",
  "object": "chat.completion",
  "created": 1698765432,
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "{\"match_score\": 85, \"resume_summary\": \"...\"}"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 1234,
    "completion_tokens": 567,
    "total_tokens": 1801
  }
}
```

**Error Response**:
```json
{
  "error": {
    "message": "Invalid API key provided",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

**Rate Limits**:
- Varies by model
- Generally 100+ requests per minute
- See: https://openrouter.ai/docs#rate-limits

**Cost Optimization**:
- Use `gpt-4o-mini` for cheaper processing
- Set `max_tokens` to minimum required (1500-2000)
- Use streaming for real-time applications

---

## Google Sheets API

### Base URL
```
https://sheets.googleapis.com/v4
```

### Authentication
- **Method**: OAuth2
- **Scopes**: `https://www.googleapis.com/auth/spreadsheets`
- **Setup**: https://developers.google.com/sheets/api/quickstart

### Common Operations

#### 1. Append Values

**URL**:
```
POST https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}/values/{RANGE}:append
```

**Query Parameters**:
- `valueInputOption`: `USER_ENTERED` or `RAW`
- `insertDataOption`: `INSERT_ROWS` or `OVERWRITE`

**Request Body**:
```json
{
  "values": [
    [
      "Senior DevOps Engineer",
      "Example Corp",
      "San Francisco, CA",
      "$150k-$180k",
      "2025-10-26T08:30:00Z",
      "indeed",
      "https://example.com/job/123",
      "Job description...",
      "new",
      "",
      "",
      ""
    ]
  ]
}
```

**Response**:
```json
{
  "spreadsheetId": "abc123",
  "tableRange": "Job Listings!A1:L1",
  "updates": {
    "spreadsheetId": "abc123",
    "updatedRange": "Job Listings!A2:L2",
    "updatedRows": 1,
    "updatedColumns": 12,
    "updatedCells": 12
  }
}
```

#### 2. Get Values (for Lookup)

**URL**:
```
GET https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}/values/{RANGE}
```

**Example**:
```
GET https://sheets.googleapis.com/v4/spreadsheets/abc123/values/Job%20Listings!A:B
```

**Response**:
```json
{
  "range": "Job Listings!A1:B100",
  "majorDimension": "ROWS",
  "values": [
    ["job_title", "company"],
    ["Senior DevOps Engineer", "Example Corp"],
    ["Cloud Architect", "Tech Inc"]
  ]
}
```

#### 3. Update Values

**URL**:
```
PUT https://sheets.googleapis.com/v4/spreadsheets/{SPREADSHEET_ID}/values/{RANGE}
```

**Request Body**:
```json
{
  "values": [
    ["review", "Tailored resume text...", "Cover letter text...", 85]
  ]
}
```

### n8n Google Sheets Node Configuration

**Operation: Append**
- Spreadsheet: Select from dropdown
- Sheet: "Job Listings"
- Data Mode: "Mapping"
- Map fields to columns

**Operation: Lookup**
- Lookup Column: "job_title"
- Lookup Value: `{{$json.job_title}}`

**Operation: Update**
- Update Key: Composite (job_title + company)
- Fields to Update: Select specific columns

**Rate Limits**:
- 100 requests per 100 seconds per user
- 500 requests per 100 seconds per project

---

## Gmail API

### Base URL
```
https://gmail.googleapis.com/gmail/v1
```

### Authentication
- **Method**: OAuth2
- **Scopes**: `https://www.googleapis.com/auth/gmail.send`
- **Setup**: https://developers.google.com/gmail/api/quickstart

### Send Email Endpoint

**URL**:
```
POST https://gmail.googleapis.com/gmail/v1/users/me/messages/send
```

**Request Body (Base64 Encoded)**:
```json
{
  "raw": "BASE64_ENCODED_EMAIL_MESSAGE"
}
```

**Email Format (before encoding)**:
```
From: your-email@gmail.com
To: candidate@example.com
Subject: [Job Hunt Auto-Pilot] Senior DevOps Engineer at Example Corp (match 85%)
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>
...
</html>
```

**Response**:
```json
{
  "id": "18b1c2d3e4f5g6h7",
  "threadId": "18b1c2d3e4f5g6h7",
  "labelIds": ["SENT"]
}
```

### n8n Gmail Node Configuration

**Operation**: Send Email
- **To**: `{{$json.email}}`
- **Subject**: `{{$json.subject}}`
- **Message Type**: HTML or Text
- **Message**: `{{$json.body}}`

**Additional Options**:
- CC/BCC: Optional
- Attachments: Not used in this workflow
- Reply To: Optional

**Rate Limits**:
- Personal Gmail: 500 emails per day
- Google Workspace: 2,000 emails per day
- Sending quota resets at midnight PST

**Error Response**:
```json
{
  "error": {
    "code": 403,
    "message": "Daily sending quota exceeded",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

---

## Environment Variables & Secrets Management

### Recommended .env Structure
```bash
# Apify
APIFY_TOKEN=apify_api_xxxxxxxxxxxxx

# Adzuna
ADZUNA_APP_ID=12345678
ADZUNA_APP_KEY=abcdef1234567890abcdef1234567890

# OpenRouter
OPENROUTER_API_KEY=sk-or-xxxxxxxxxxxxx

# Google (from OAuth2 flow)
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxxxxxxxxxx
GOOGLE_REFRESH_TOKEN=xxxxxxxxxxxxx

# Google Sheet
SPREADSHEET_ID=1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789

# Email
DEFAULT_EMAIL=candidate@example.com
```

### Security Best Practices
1. ✅ Store all secrets in n8n credentials, not in workflow code
2. ✅ Use environment variables for configuration
3. ✅ Rotate API keys every 90 days
4. ✅ Monitor API usage for anomalies
5. ✅ Enable 2FA on all service accounts
6. ✅ Use service accounts for Google APIs
7. ✅ Restrict OAuth scopes to minimum required
8. ✅ Audit API access logs monthly

---

## Testing Endpoints

### Test Apify Connection
```bash
curl -X GET "https://api.apify.com/v2/actor-stores" \
  -H "Authorization: Bearer YOUR_APIFY_TOKEN"
```

### Test Adzuna Connection
```bash
curl -X GET "https://api.adzuna.com/v1/api/jobs/us/search/1?app_id=YOUR_APP_ID&app_key=YOUR_APP_KEY&results_per_page=1&what=engineer"
```

### Test OpenRouter Connection
```bash
curl -X POST "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Test Google Sheets Connection
```bash
curl -X GET "https://sheets.googleapis.com/v4/spreadsheets/YOUR_SPREADSHEET_ID?fields=sheets.properties" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## API Cost Calculator

### Sample Job Hunt Run (50 jobs)

| Service | Operation | Cost per Run |
|---------|-----------|--------------|
| Apify Indeed | 50 jobs | $0.0125 |
| Apify LinkedIn | 50 jobs | $0.025 |
| Apify Glassdoor | 50 jobs | $0.015 |
| Apify Upwork | 50 jobs | $0.025 |
| Adzuna | 1 API call | $0 (free) |
| **Scrapers Total** | | **$0.0775** |
| | | |
| OpenRouter Claude | 30 jobs × 3 models | $1.80 |
| OpenRouter GPT-4o-mini | 30 jobs | $0.12 |
| OpenRouter Gemini | 30 jobs | $0.30 |
| **AI Total** | | **$2.22** |
| | | |
| Google Sheets | 100 operations | $0 (free) |
| Gmail | 30 emails | $0 (free) |
| | | |
| **Grand Total per Run** | | **~$2.30** |

### Monthly Cost Estimate
- **Daily runs**: $2.30 × 30 = $69/month
- **Weekly runs**: $2.30 × 4 = $9.20/month
- **On-demand only**: Variable

---

**End of API Configuration Reference**

Use this document to configure all external API integrations in your n8n workflow.
