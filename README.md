# n8n Job Hunter

An automated job search workflow for n8n that searches multiple job platforms (LinkedIn, Indeed, Glassdoor, Upwork, and Adzuna), deduplicates results, saves them to Google Sheets, uses AI to tailor your resume and cover letter for each job, and sends you a daily email summary.

## Features

- 🔍 **Multi-Platform Job Search**: Searches 5 major job platforms
  - LinkedIn (via Apify)
  - Indeed (via Apify)
  - Glassdoor (via Apify)
  - Upwork (via Apify)
  - Adzuna (via API)
  
- 🎯 **Smart Deduplication**: Removes duplicate job postings across platforms

- 📊 **Google Sheets Integration**: Automatically saves and organizes job listings

- 🤖 **AI-Powered Customization**: Uses OpenRouter AI to:
  - Tailor your resume for each specific job
  - Generate customized cover letters
  
- 📧 **Email Reports**: Sends daily summaries with top job matches

- ⚡ **Automated Scheduling**: Runs daily to keep your job search current

## Prerequisites

Before setting up this workflow, you'll need:

1. **Self-hosted n8n instance** (or n8n cloud)
2. **API Accounts & Keys**:
   - [Apify](https://apify.com/) - For web scraping LinkedIn, Indeed, Glassdoor, Upwork
   - [Adzuna](https://developer.adzuna.com/) - For job search API
   - [OpenRouter](https://openrouter.ai/) - For AI resume/cover letter tailoring
   - [Google Cloud](https://console.cloud.google.com/) - For Google Sheets access
   - Gmail account with OAuth2 configured

## Quick Start

### 1. Install n8n

**Using Docker (Recommended for self-hosted):**

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Using npm:**

```bash
npm install -g n8n
n8n start
```

Access n8n at `http://localhost:5678`

### 2. Import the Workflow

1. Download `job-hunter-workflow.json` from this repository
2. In n8n, click **Workflows** → **Import from File**
3. Select the downloaded JSON file
4. The workflow will be imported with all nodes configured

### 3. Configure Credentials

You'll need to set up the following credentials in n8n:

#### Apify API
1. Go to **Settings** → **Credentials** → **New**
2. Select **HTTP Header Auth**
3. Name: `Apify API`
4. Header Name: `Authorization`
5. Header Value: `Bearer YOUR_APIFY_API_KEY`

#### Adzuna API
1. Create custom credential or use HTTP Basic Auth
2. Store your Adzuna App ID and App Key

#### OpenRouter API
1. Go to **Settings** → **Credentials** → **New**
2. Select **HTTP Header Auth**
3. Name: `OpenRouter API`
4. Header Name: `Authorization`
5. Header Value: `Bearer YOUR_OPENROUTER_API_KEY`

#### Google Sheets OAuth2
1. Follow [n8n's Google Sheets credential guide](https://docs.n8n.io/integrations/builtin/credentials/google/)
2. Enable Google Sheets API in Google Cloud Console
3. Create OAuth2 credentials
4. Configure in n8n

#### Gmail OAuth2
1. Follow [n8n's Gmail credential guide](https://docs.n8n.io/integrations/builtin/credentials/google/)
2. Enable Gmail API in Google Cloud Console
3. Use same or different OAuth2 credentials as Google Sheets
4. Configure in n8n

### 4. Set Environment Variables

In your n8n instance, set the following environment variables:

```bash
# Google Sheet ID (from the URL: docs.google.com/spreadsheets/d/SHEET_ID/edit)
GOOGLE_SHEET_ID=your_google_sheet_id

# Your email to receive job reports
RECIPIENT_EMAIL=your.email@example.com

# Your resume text (can be multi-line)
USER_RESUME_TEXT="Your resume content here..."

# Your cover letter template
USER_COVER_LETTER_TEMPLATE="Dear Hiring Manager,\n\n..."
```

**For Docker:**
Create a `.env` file and mount it:

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  --env-file .env \
  n8nio/n8n
```

### 5. Prepare Google Sheet

1. Create a new Google Sheet
2. Name the first sheet `Jobs`
3. Add the following column headers:
   - Title
   - Company
   - Location
   - Description
   - URL
   - Salary
   - Posted Date
   - Source
   - Status
   - Applied
   - Date Found
   - Tailored Resume
   - Cover Letter
   - AI Processed

4. Copy the Sheet ID from the URL and set it as `GOOGLE_SHEET_ID`

### 6. Customize Job Search Parameters

In the workflow, open the **Set Job Parameters** node and configure:

- `keyword`: Job title or keywords (e.g., "software engineer", "data scientist")
- `location`: Location (e.g., "San Francisco, CA", "New York, NY")
- `country`: Country code for Adzuna (e.g., "us", "gb", "ca")
- `maxResults`: Number of results per platform (e.g., "50")

### 7. Activate the Workflow

1. Click **Active** toggle in the top right
2. The workflow will run daily (default: every 24 hours)
3. You can also click **Execute Workflow** to test it immediately

## Workflow Architecture

```
Schedule Trigger (Daily)
    ↓
Set Job Parameters
    ↓
[Parallel Search Across Platforms]
    ├─→ Apify LinkedIn
    ├─→ Apify Indeed
    ├─→ Apify Glassdoor
    ├─→ Apify Upwork
    └─→ Adzuna API
    ↓
[Process & Merge Results]
    ├─→ Wait for Apify Results
    └─→ Process Adzuna Results
    ↓
Merge All Results
    ↓
Normalize Job Data
    ↓
Deduplicate Jobs
    ↓
Save to Google Sheets
    ↓
Load User Documents (Resume/Cover Letter)
    ↓
OpenRouter AI - Tailor Documents
    ↓
Process AI Response
    ↓
Update Sheet with AI Content
    ↓
Prepare Email Summary
    ↓
Send Gmail Summary
```

## Node Configuration Details

### Schedule Trigger
- **Type**: Schedule Trigger
- **Interval**: Every 1 day
- **Purpose**: Automatically runs the workflow daily

### Apify Nodes (LinkedIn, Indeed, Glassdoor, Upwork)
- **Type**: HTTP Request
- **Method**: POST
- **Purpose**: Initiates scraping jobs on Apify platform
- **Note**: Uses Apify's actor runs API to scrape job listings

### Adzuna API Node
- **Type**: HTTP Request
- **Method**: GET
- **Purpose**: Searches Adzuna job database via their public API

### Wait for Apify Results
- **Type**: Code (JavaScript)
- **Purpose**: Polls Apify until scraping jobs complete and fetches results
- **Note**: Implements retry logic with 10-second intervals

### Process Adzuna Results
- **Type**: Code (JavaScript)
- **Purpose**: Normalizes Adzuna API response to match format of other sources

### Normalize Job Data
- **Type**: Code (JavaScript)
- **Purpose**: Standardizes job data from all sources into a common format

### Deduplicate Jobs
- **Type**: Code (JavaScript)
- **Purpose**: Removes duplicate jobs based on title, company, and location

### OpenRouter AI - Tailor Documents
- **Type**: HTTP Request
- **Method**: POST to OpenRouter API
- **Purpose**: Uses GPT-4 to create job-specific resumes and cover letters
- **Model**: OpenAI GPT-4 Turbo (customizable)

## Customization Options

### Change Search Frequency
Edit the **Schedule Trigger** node:
- Daily: `{ "field": "days", "daysInterval": 1 }`
- Twice daily: `{ "field": "hours", "hoursInterval": 12 }`
- Weekly: `{ "field": "days", "daysInterval": 7 }`

### Modify AI Model
In the **OpenRouter AI** node, change the `model` field:
- `openai/gpt-4-turbo` (default, best quality)
- `openai/gpt-3.5-turbo` (faster, cheaper)
- `anthropic/claude-2` (alternative)
- See [OpenRouter models](https://openrouter.ai/models) for full list

### Filter Jobs by Criteria
Add a **Filter** node after **Deduplicate Jobs** to filter by:
- Salary range
- Keywords in description
- Specific companies
- Remote vs on-site

### Add More Job Sources
You can add additional Apify scrapers or APIs:
1. Add a new HTTP Request node
2. Configure the API/scraper
3. Add processing logic if needed
4. Connect to the **Merge All Results** node

## Troubleshooting

### Apify Jobs Not Completing
- Check your Apify account for rate limits
- Increase wait time in **Wait for Apify Results** node
- Verify Apify API key is correct

### Google Sheets Not Updating
- Ensure OAuth2 credentials are valid
- Check that the Sheet ID is correct
- Verify the sheet name is exactly `Jobs`
- Make sure you have edit permissions

### AI Tailoring Fails
- Verify OpenRouter API key is valid
- Check that you have credits in your OpenRouter account
- Ensure resume/cover letter environment variables are set
- Check the AI model is available

### Email Not Sending
- Verify Gmail OAuth2 credentials
- Check that Gmail API is enabled
- Ensure recipient email is set correctly
- Check spam folder

### No Jobs Found
- Verify API credentials for all services
- Check search parameters (keyword, location)
- Try broader search terms
- Check individual platform results to identify which source is failing

## Cost Estimation

Approximate monthly costs for running this workflow daily:

- **Apify**: $49/month (includes 100 actor runs)
- **Adzuna API**: Free tier (up to 1,000 calls/month)
- **OpenRouter**: ~$0.01-0.05 per job (GPT-4 Turbo pricing)
- **Google Sheets**: Free
- **Gmail**: Free
- **n8n**: Free (self-hosted) or from $20/month (cloud)

**Total estimated cost**: ~$50-100/month for daily automated job search

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for sensitive data
3. **Rotate credentials** regularly
4. **Limit API permissions** to only what's needed
5. **Monitor API usage** to prevent unexpected charges
6. **Use HTTPS** for all n8n connections
7. **Keep n8n updated** to the latest version

## Advanced Features

### Add Job Application Tracking
Modify the Google Sheets to track:
- Application status
- Interview dates
- Follow-up reminders

### Integrate with Job Application Platforms
Add nodes to automatically:
- Apply to jobs on certain platforms
- Track application submissions
- Set follow-up reminders

### Add Filtering by Skills
Enhance the AI prompt to score jobs based on:
- Skills match
- Experience requirements
- Salary expectations

### Create a Dashboard
Use Google Data Studio or similar to visualize:
- Jobs found per day
- Success rate by platform
- Application funnel

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify for your needs.

## Support

For issues and questions:
1. Check the [n8n documentation](https://docs.n8n.io/)
2. Visit the [n8n community forum](https://community.n8n.io/)
3. Open an issue in this repository

## Acknowledgments

- Built for [n8n.io](https://n8n.io/) - workflow automation platform
- Uses [Apify](https://apify.com/) for web scraping
- Uses [Adzuna](https://www.adzuna.com/) for job search
- Uses [OpenRouter](https://openrouter.ai/) for AI capabilities

---

**Happy Job Hunting! 🎯**