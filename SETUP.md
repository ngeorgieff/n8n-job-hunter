# n8n Job Hunter - Detailed Setup Guide

This guide provides step-by-step instructions for setting up the n8n Job Hunter workflow from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setting Up n8n](#setting-up-n8n)
3. [Obtaining API Credentials](#obtaining-api-credentials)
4. [Configuring the Workflow](#configuring-the-workflow)
5. [Testing the Workflow](#testing-the-workflow)
6. [Production Deployment](#production-deployment)
7. [Maintenance and Monitoring](#maintenance-and-monitoring)

## Prerequisites

### Required Accounts

Before starting, create accounts on the following platforms:

- [ ] [Apify](https://apify.com/) - Web scraping platform
- [ ] [Adzuna](https://developer.adzuna.com/) - Job search API
- [ ] [OpenRouter](https://openrouter.ai/) - AI API aggregator
- [ ] [Google Cloud](https://console.cloud.google.com/) - For Sheets & Gmail
- [ ] Gmail account for sending emails

### System Requirements

**For Self-Hosted n8n:**
- Docker installed OR Node.js 18+ installed
- Minimum 1GB RAM
- 10GB available disk space
- Linux/Mac/Windows with WSL2

**For n8n Cloud:**
- Just a browser and internet connection

## Setting Up n8n

### Option 1: Self-Hosted with Docker (Recommended)

1. **Install Docker**
   ```bash
   # For Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # For macOS (install Docker Desktop)
   # Download from: https://www.docker.com/products/docker-desktop
   ```

2. **Create n8n Directory**
   ```bash
   mkdir -p ~/.n8n
   cd ~/.n8n
   ```

3. **Create Environment File**
   ```bash
   nano .env
   ```
   
   Add the following content:
   ```env
   # n8n Configuration
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=your_secure_password_here
   
   # Timezone
   GENERIC_TIMEZONE=America/New_York
   
   # Webhook URL (change to your domain if using production)
   WEBHOOK_URL=http://localhost:5678/
   
   # Google Sheet Configuration
   GOOGLE_SHEET_ID=your_sheet_id_here
   
   # Email Configuration
   RECIPIENT_EMAIL=your.email@example.com
   
   # Resume and Cover Letter (add these after preparing your documents)
   USER_RESUME_TEXT=""
   USER_COVER_LETTER_TEMPLATE=""
   ```

4. **Start n8n Container**
   ```bash
   docker run -d \
     --name n8n \
     -p 5678:5678 \
     -v ~/.n8n:/home/node/.n8n \
     --env-file ~/.n8n/.env \
     --restart unless-stopped \
     n8nio/n8n
   ```

5. **Verify n8n is Running**
   ```bash
   docker ps
   docker logs n8n
   ```

6. **Access n8n**
   - Open browser to `http://localhost:5678`
   - Login with credentials from `.env` file

### Option 2: Self-Hosted with npm

1. **Install Node.js 18+**
   ```bash
   # Using nvm (recommended)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

2. **Install n8n Globally**
   ```bash
   npm install -g n8n
   ```

3. **Set Environment Variables**
   ```bash
   export N8N_BASIC_AUTH_ACTIVE=true
   export N8N_BASIC_AUTH_USER=admin
   export N8N_BASIC_AUTH_PASSWORD=your_password
   export GOOGLE_SHEET_ID=your_sheet_id
   export RECIPIENT_EMAIL=your.email@example.com
   ```

4. **Start n8n**
   ```bash
   n8n start
   ```

### Option 3: n8n Cloud

1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up for an account
3. Choose a plan (Starter plan is sufficient)
4. Your n8n instance will be ready immediately

## Obtaining API Credentials

### 1. Apify API Key

1. **Sign up for Apify**
   - Go to [apify.com](https://apify.com/)
   - Click "Start for free"
   - Complete registration

2. **Get API Token**
   - Go to [Settings → Integrations](https://console.apify.com/account#/integrations)
   - Copy your API token
   - Save it securely

3. **Subscribe to Required Actors** (Optional but recommended)
   - [LinkedIn Jobs Scraper](https://apify.com/apify/linkedin-jobs-scraper)
   - [Indeed Scraper](https://apify.com/apify/indeed-scraper)
   - [Glassdoor Scraper](https://apify.com/apify/glassdoor-scraper)
   - [Upwork Jobs Scraper](https://apify.com/apify/upwork-jobs-scraper)

   Note: Most scrapers work on the free tier for testing.

### 2. Adzuna API Credentials

1. **Register for API Access**
   - Go to [developer.adzuna.com](https://developer.adzuna.com/)
   - Click "Register"
   - Fill out the application form

2. **Get API Credentials**
   - After approval, login to your developer account
   - Navigate to API keys section
   - Copy your App ID and App Key
   - Save them securely

### 3. OpenRouter API Key

1. **Create OpenRouter Account**
   - Go to [openrouter.ai](https://openrouter.ai/)
   - Click "Sign In" and create account
   - Can sign in with Google or GitHub

2. **Add Credits**
   - Go to [Keys & Credits](https://openrouter.ai/keys)
   - Add at least $5 to start (recommended $10-20)
   - GPT-4 Turbo costs ~$0.01-0.05 per job tailoring

3. **Generate API Key**
   - In the Keys section, click "Create Key"
   - Name it "n8n Job Hunter"
   - Copy and save the key securely

### 4. Google Cloud Setup (Sheets & Gmail)

1. **Create Google Cloud Project**
   - Go to [console.cloud.google.com](https://console.cloud.google.com/)
   - Click "Create Project"
   - Name: "n8n-job-hunter"
   - Click "Create"

2. **Enable APIs**
   ```
   - Navigate to "APIs & Services" → "Library"
   - Search and enable "Google Sheets API"
   - Search and enable "Gmail API"
   ```

3. **Create OAuth Consent Screen**
   - Go to "APIs & Services" → "OAuth consent screen"
   - Choose "External" user type
   - Fill in required fields:
     - App name: "n8n Job Hunter"
     - User support email: your email
     - Developer contact: your email
   - Click "Save and Continue"
   - Add scopes:
     - `.../auth/spreadsheets`
     - `.../auth/gmail.send`
   - Add your email as test user
   - Click "Save and Continue"

4. **Create OAuth Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: "Web application"
   - Name: "n8n Job Hunter"
   - Authorized redirect URIs:
     - For local: `http://localhost:5678/rest/oauth2-credential/callback`
     - For production: `https://your-domain.com/rest/oauth2-credential/callback`
   - Click "Create"
   - Save Client ID and Client Secret

### 5. Create Google Sheet

1. **Create New Sheet**
   - Go to [sheets.google.com](https://sheets.google.com/)
   - Click "Blank" to create new sheet
   - Name it "Job Hunter Results"

2. **Set Up Columns**
   In the first row, add these headers:
   ```
   A: Title
   B: Company
   C: Location
   D: Description
   E: URL
   F: Salary
   G: Posted Date
   H: Source
   I: Status
   J: Applied
   K: Date Found
   L: Tailored Resume
   M: Cover Letter
   N: AI Processed
   ```

3. **Get Sheet ID**
   - From the URL: `https://docs.google.com/spreadsheets/d/SHEET_ID/edit`
   - Copy the `SHEET_ID` part
   - Save it for configuration

4. **Share with yourself** (ensure you have edit access)

## Configuring the Workflow

### 1. Import Workflow

1. **Download Workflow File**
   - Download `job-hunter-workflow.json` from this repository

2. **Import into n8n**
   - In n8n, click "Workflows" in sidebar
   - Click "Import from File"
   - Select the downloaded JSON file
   - Click "Import"

### 2. Configure Credentials in n8n

#### Apify API Credential

1. Go to "Settings" → "Credentials" → "New"
2. Search for "HTTP Header Auth"
3. Configure:
   - **Credential name**: `Apify API`
   - **Name**: `Authorization`
   - **Value**: `Bearer YOUR_APIFY_API_TOKEN`
4. Click "Save"

#### Adzuna API Credential

1. Go to "Settings" → "Credentials" → "New"
2. Search for "Header Auth"
3. Create custom header auth or modify HTTP Request nodes to use query parameters
4. For query parameters (easier):
   - No credential needed
   - Parameters are set in the HTTP Request node directly

#### OpenRouter API Credential

1. Go to "Settings" → "Credentials" → "New"
2. Search for "HTTP Header Auth"
3. Configure:
   - **Credential name**: `OpenRouter API`
   - **Name**: `Authorization`
   - **Value**: `Bearer YOUR_OPENROUTER_API_KEY`
4. Click "Save"

#### Google Sheets OAuth2

1. Go to "Settings" → "Credentials" → "New"
2. Search for "Google Sheets OAuth2 API"
3. Configure:
   - **Credential name**: `Google Sheets OAuth2`
   - **Client ID**: From Google Cloud Console
   - **Client Secret**: From Google Cloud Console
4. Click "Connect my account"
5. Follow OAuth flow to authorize
6. Click "Save"

#### Gmail OAuth2

1. Go to "Settings" → "Credentials" → "New"
2. Search for "Gmail OAuth2 API"
3. Configure:
   - **Credential name**: `Gmail OAuth2`
   - **Client ID**: Same as Google Sheets
   - **Client Secret**: Same as Google Sheets
4. Click "Connect my account"
5. Follow OAuth flow to authorize
6. Click "Save"

### 3. Link Credentials to Workflow Nodes

Open the imported workflow and verify each node has credentials assigned:

1. **Apify LinkedIn Jobs** → Credentials → Select "Apify API"
2. **Apify Indeed Jobs** → Credentials → Select "Apify API"
3. **Apify Glassdoor Jobs** → Credentials → Select "Apify API"
4. **Apify Upwork Jobs** → Credentials → Select "Apify API"
5. **Save to Google Sheets** → Credentials → Select "Google Sheets OAuth2"
6. **Update Sheet with AI Content** → Credentials → Select "Google Sheets OAuth2"
7. **OpenRouter AI** → Credentials → Select "OpenRouter API"
8. **Send Gmail Summary** → Credentials → Select "Gmail OAuth2"

### 4. Configure Environment Variables

Update your `.env` file or environment variables:

```env
# Google Sheet ID (from URL)
GOOGLE_SHEET_ID=1abc123def456ghi789jkl

# Recipient email
RECIPIENT_EMAIL=your.email@example.com

# Your resume (can be multi-line)
USER_RESUME_TEXT="John Doe
123 Main St, San Francisco, CA 94102
john.doe@email.com | (555) 123-4567

PROFESSIONAL SUMMARY
Experienced software engineer with 5+ years...

EXPERIENCE
Senior Software Engineer | Tech Corp | 2020-Present
- Led development of microservices architecture
- Improved system performance by 40%
..."

# Cover letter template
USER_COVER_LETTER_TEMPLATE="Dear Hiring Manager,

I am writing to express my interest in the [POSITION] role at [COMPANY]. With my background in software engineering and proven track record of delivering high-quality solutions, I am confident I would be a valuable addition to your team.

[TAILORED CONTENT HERE]

Thank you for considering my application. I look forward to discussing how my skills and experience align with your needs.

Best regards,
John Doe"
```

For Docker, restart the container:
```bash
docker restart n8n
```

### 5. Customize Job Search Parameters

In the workflow, open the **Set Job Parameters** node:

1. Click on the node to open it
2. Modify the values:
   ```javascript
   keyword: "software engineer"           // Your job search keywords
   location: "San Francisco, CA"          // Desired location
   country: "us"                          // Country code (us, gb, ca, etc.)
   maxResults: "50"                       // Max results per platform
   ```
3. Click "Save"

## Testing the Workflow

### 1. Test Individual Nodes

Before running the full workflow, test individual nodes:

1. **Test Adzuna API** (easiest to test first)
   - Open "Set Job Parameters" node
   - Click "Execute Node"
   - Open "Adzuna API Jobs" node
   - Click "Execute Node"
   - Verify you see job results in the output

2. **Test Google Sheets**
   - Open "Save to Google Sheets" node
   - Add test data manually or use Adzuna results
   - Click "Execute Node"
   - Check your Google Sheet for new row

3. **Test Email**
   - Open "Send Gmail Summary" node
   - Add test data
   - Click "Execute Node"
   - Check your inbox

### 2. Test Full Workflow (Without Apify First)

1. **Disable Apify Nodes Temporarily**
   - Right-click each Apify node
   - Select "Disable"
   - This allows testing with just Adzuna

2. **Execute Workflow**
   - Click "Execute Workflow" button (top right)
   - Monitor progress in the execution log
   - Check for errors

3. **Verify Results**
   - Check Google Sheet for new entries
   - Check email inbox for summary
   - Verify data looks correct

### 3. Test with Apify (Full Workflow)

1. **Re-enable Apify Nodes**
   - Right-click each Apify node
   - Select "Enable"

2. **Reduce maxResults for Testing**
   - In "Set Job Parameters", set `maxResults: "5"`
   - This limits API usage during testing

3. **Execute Workflow**
   - Click "Execute Workflow"
   - Note: This will take 5-10 minutes due to Apify scraping
   - Monitor the "Wait for Apify Results" node

4. **Verify All Sources**
   - Check Google Sheet for jobs from all sources
   - Verify deduplication worked
   - Check that AI tailoring ran
   - Verify email was sent

## Production Deployment

### 1. Activate Workflow

1. **Set Production Parameters**
   - In "Set Job Parameters", set realistic `maxResults` (20-50)
   - Verify all credentials are production-ready

2. **Enable Workflow**
   - Toggle "Active" switch (top right)
   - Workflow will now run on schedule (daily)

3. **Verify Schedule**
   - Open "Schedule Trigger" node
   - Confirm interval (default: every 1 day)
   - Adjust if needed

### 2. Secure Your Instance

1. **Change Default Password**
   - If using Docker, update `.env` file
   - Use strong, unique password

2. **Enable HTTPS** (for production domains)
   ```bash
   # Using nginx reverse proxy
   sudo apt install nginx certbot python3-certbot-nginx
   
   # Configure nginx for n8n
   sudo nano /etc/nginx/sites-available/n8n
   ```
   
   Add:
   ```nginx
   server {
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:5678;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```
   
   ```bash
   sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
   sudo certbot --nginx -d your-domain.com
   sudo systemctl restart nginx
   ```

3. **Firewall Configuration**
   ```bash
   # Allow only SSH and HTTPS
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw enable
   ```

### 3. Set Up Monitoring

1. **Docker Logs**
   ```bash
   # View logs
   docker logs -f n8n
   
   # Save logs to file
   docker logs n8n > n8n-logs.txt
   ```

2. **n8n Execution Log**
   - In n8n, go to "Executions"
   - Review failed executions
   - Set up alerts for failures (if using n8n cloud)

3. **Monitor API Usage**
   - Check Apify dashboard for usage
   - Monitor OpenRouter credits
   - Verify Adzuna API calls

## Maintenance and Monitoring

### Regular Tasks

**Weekly:**
- [ ] Check execution logs for errors
- [ ] Review Google Sheet for quality of jobs
- [ ] Verify email summaries are being received
- [ ] Check API credit balances

**Monthly:**
- [ ] Update job search parameters if needed
- [ ] Review and adjust maxResults based on results
- [ ] Update resume/cover letter templates
- [ ] Check for n8n updates

**Quarterly:**
- [ ] Review API costs and optimize if needed
- [ ] Rotate API credentials
- [ ] Backup workflow JSON file
- [ ] Review and update security settings

### Troubleshooting Common Issues

#### No Jobs Found
```bash
# Check individual API responses
1. Test Adzuna node first (most reliable)
2. Check Apify run status in Apify dashboard
3. Verify search parameters aren't too specific
4. Check API rate limits
```

#### Workflow Fails at AI Step
```bash
# Verify OpenRouter
1. Check API key is valid
2. Verify credits available
3. Test with smaller batch of jobs
4. Check model availability
```

#### Google Sheets Not Updating
```bash
# OAuth token may have expired
1. Go to Credentials in n8n
2. Reconnect Google Sheets OAuth2
3. Verify Sheet ID is correct
4. Check sheet permissions
```

#### High API Costs
```bash
# Optimize usage
1. Reduce maxResults in parameters
2. Reduce AI processing (skip for some jobs)
3. Increase schedule interval (run less frequently)
4. Use cheaper AI model (gpt-3.5-turbo)
```

### Backup and Recovery

1. **Backup Workflow**
   ```bash
   # Export workflow JSON regularly
   # In n8n: Workflows → ... → Download
   ```

2. **Backup Data**
   ```bash
   # Export Google Sheet as CSV
   # In Sheets: File → Download → CSV
   ```

3. **Backup Configuration**
   ```bash
   # Backup .env file
   cp ~/.n8n/.env ~/.n8n/.env.backup
   
   # Backup entire n8n directory
   tar -czf n8n-backup-$(date +%Y%m%d).tar.gz ~/.n8n
   ```

### Optimizations

1. **Reduce AI Costs**
   - Process only top N jobs (add filter)
   - Use cheaper model for initial screening
   - Batch process jobs less frequently

2. **Improve Performance**
   - Process platforms in parallel (already configured)
   - Cache results to avoid duplicates
   - Optimize deduplication logic

3. **Better Results**
   - Fine-tune search parameters
   - Add custom filtering logic
   - Integrate additional job boards
   - Add ranking/scoring system

## Next Steps

After setup is complete:

1. ✅ Monitor first few executions closely
2. ✅ Adjust search parameters based on results
3. ✅ Customize resume/cover letter templates
4. ✅ Set up job application tracking
5. ✅ Add custom filters for better matches
6. ✅ Consider adding more job platforms

## Getting Help

If you encounter issues:

1. **Check n8n Docs**: [docs.n8n.io](https://docs.n8n.io/)
2. **n8n Community**: [community.n8n.io](https://community.n8n.io/)
3. **GitHub Issues**: Open an issue in this repository
4. **API Documentation**:
   - [Apify Docs](https://docs.apify.com/)
   - [Adzuna API Docs](https://developer.adzuna.com/docs)
   - [OpenRouter Docs](https://openrouter.ai/docs)

## Summary Checklist

Before going live, verify:

- [ ] n8n is installed and accessible
- [ ] All API credentials are configured
- [ ] Google Sheet is created and ID is set
- [ ] Environment variables are set correctly
- [ ] Resume and cover letter templates are added
- [ ] Workflow is imported successfully
- [ ] All nodes have credentials assigned
- [ ] Test execution completed successfully
- [ ] Email summary was received
- [ ] Schedule trigger is configured
- [ ] Workflow is activated
- [ ] Security measures are in place
- [ ] Monitoring is set up
- [ ] Backup plan is established

Congratulations! Your automated job hunter is now ready to find opportunities for you! 🎉
