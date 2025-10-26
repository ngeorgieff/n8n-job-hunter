# Quick Start Guide

Get your n8n Job Hunter up and running in 15 minutes!

## Prerequisites Checklist

Before you begin, make sure you have:

- [ ] Computer with Docker installed (or Node.js 18+)
- [ ] Gmail account
- [ ] 30 minutes of time for initial setup
- [ ] Credit card for API services (most have free tiers)

## 5-Step Quick Start

### Step 1: Install n8n (5 minutes)

**Using Docker (Recommended):**

```bash
# Create directory for n8n
mkdir -p ~/.n8n

# Start n8n
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Verify it's running
docker ps | grep n8n
```

**Open n8n:** http://localhost:5678

### Step 2: Create API Accounts (10 minutes)

Create accounts and get API keys for these services:

#### 2.1 Apify (Required)
1. Go to https://apify.com/
2. Sign up (free tier available)
3. Get API token: https://console.apify.com/account#/integrations
4. **Save the token** - you'll need it soon

#### 2.2 Adzuna (Required)
1. Go to https://developer.adzuna.com/
2. Register for API access
3. Get App ID and App Key
4. **Save both** - you'll need them soon

#### 2.3 OpenRouter (Required)
1. Go to https://openrouter.ai/
2. Sign up
3. Add $10 credit (for AI processing)
4. Create API key: https://openrouter.ai/keys
5. **Save the key** - you'll need it soon

#### 2.4 Google Cloud (Required)
1. Go to https://console.cloud.google.com/
2. Create new project: "n8n-job-hunter"
3. Enable APIs:
   - Google Sheets API
   - Gmail API
4. Create OAuth credentials:
   - Type: Web application
   - Redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
5. **Save Client ID and Secret** - you'll need them soon

### Step 3: Import Workflow (2 minutes)

1. **Download workflow:**
   - Get `job-hunter-workflow.json` from this repository

2. **Import into n8n:**
   - In n8n, click "Workflows" → "Import from File"
   - Select the downloaded JSON file
   - Click "Import"

3. **Verify import:**
   - You should see a workflow with 19 nodes
   - Don't worry about the red dots (missing credentials) - we'll fix that next

### Step 4: Configure Credentials (5 minutes)

#### 4.1 Apify Credential

1. In n8n: Settings → Credentials → New
2. Search for "HTTP Header Auth"
3. Fill in:
   - Name: `Apify API`
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_APIFY_TOKEN`
4. Save

#### 4.2 OpenRouter Credential

1. Settings → Credentials → New
2. Search for "HTTP Header Auth"
3. Fill in:
   - Name: `OpenRouter API`
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_OPENROUTER_KEY`
4. Save

#### 4.3 Google Sheets Credential

1. Settings → Credentials → New
2. Search for "Google Sheets OAuth2 API"
3. Fill in:
   - Name: `Google Sheets OAuth2`
   - Client ID: (from Google Cloud)
   - Client Secret: (from Google Cloud)
4. Click "Connect my account"
5. Authorize access
6. Save

#### 4.4 Gmail Credential

1. Settings → Credentials → New
2. Search for "Gmail OAuth2 API"
3. Use same Client ID/Secret as Google Sheets
4. Click "Connect my account"
5. Authorize access
6. Save

### Step 5: Setup & Test (3 minutes)

#### 5.1 Create Google Sheet

1. Go to https://sheets.google.com
2. Create new sheet named "Job Hunter Results"
3. Rename first sheet to "Jobs"
4. Add these column headers in row 1:
   ```
   Title | Company | Location | Description | URL | Salary | Posted Date | Source | Status | Applied | Date Found | Tailored Resume | Cover Letter | AI Processed
   ```
5. Copy the Sheet ID from URL (between `/d/` and `/edit`)

#### 5.2 Configure Environment Variables

**For Docker:**

```bash
# Stop n8n
docker stop n8n

# Create environment file
cat > ~/.n8n/.env << 'EOF'
GOOGLE_SHEET_ID=YOUR_SHEET_ID_HERE
RECIPIENT_EMAIL=your.email@example.com
USER_RESUME_TEXT="Your Name
Your Address
your.email@example.com

EXPERIENCE
- Your job experience here

SKILLS
- Your skills here"

USER_COVER_LETTER_TEMPLATE="Dear Hiring Manager,

I am interested in the position at your company.

Best regards,
Your Name"
EOF

# Restart with environment file
docker rm n8n
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  --env-file ~/.n8n/.env \
  n8nio/n8n
```

#### 5.3 Test the Workflow

1. **Configure search parameters:**
   - Open "Set Job Parameters" node
   - Set your desired:
     - keyword: e.g., "software engineer"
     - location: e.g., "San Francisco, CA"
     - country: e.g., "us"
     - maxResults: start with "10" for testing

2. **Test with Adzuna only (fastest):**
   - Right-click the 4 Apify nodes
   - Select "Disable" for each
   - This lets you test faster

3. **Execute workflow:**
   - Click "Execute Workflow" button
   - Watch it run (should take ~30 seconds)

4. **Verify results:**
   - Check Google Sheet for new jobs
   - Check your email for summary
   - Check execution log for errors

5. **Enable full workflow:**
   - Right-click the 4 Apify nodes
   - Select "Enable" for each
   - Run again (will take 5-10 minutes)

## Troubleshooting Quick Fixes

### "Unauthorized" errors
→ Check API keys are correct and have no extra spaces

### "Sheet not found" error
→ Verify sheet name is exactly "Jobs" and Sheet ID is correct

### "OAuth error" for Google
→ Make sure redirect URI in Google Cloud matches exactly what n8n shows

### No jobs found
→ Try broader search terms or different location

### Workflow hangs
→ Check Apify dashboard to see if runs are stuck

## Next Steps

After successful test:

1. **Activate scheduled runs:**
   - Toggle "Active" switch in workflow
   - It will now run daily automatically

2. **Customize your search:**
   - Adjust keyword and location
   - Modify maxResults (20-50 recommended)

3. **Update your resume:**
   - Edit `USER_RESUME_TEXT` environment variable
   - Make it detailed for better AI tailoring

4. **Monitor results:**
   - Check executions daily for first week
   - Review job quality
   - Adjust parameters as needed

## Cost Estimate

**Monthly costs with daily runs:**

| Service | Free Tier | Paid |
|---------|-----------|------|
| n8n (self-hosted) | Free | - |
| Apify | 100 runs/month | $49/month |
| Adzuna | 1,000 calls/month | Varies |
| OpenRouter | - | ~$10-30/month |
| Google Sheets | Free | - |
| Gmail | Free | - |

**Total: ~$50-80/month** for fully automated job search

## Tips for Success

1. **Start small:** Test with 10 results first, then scale up
2. **Monitor costs:** Check OpenRouter credits weekly
3. **Refine search:** Adjust keywords based on results
4. **Review quality:** Check jobs in sheet regularly
5. **Customize AI:** Update resume/cover letter for better results

## Getting Help

If you get stuck:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
2. Review [SETUP.md](SETUP.md) for detailed instructions
3. Check [NODE_CONFIG.md](NODE_CONFIG.md) for node configuration
4. Ask in [n8n Community](https://community.n8n.io/)

## What's Next?

Once your workflow is running smoothly:

- [ ] Set up job application tracking in the sheet
- [ ] Add filters for salary/location preferences
- [ ] Create custom email templates
- [ ] Add more job platforms
- [ ] Set up alerts for high-priority jobs
- [ ] Integrate with application tracking systems

---

**Congratulations!** Your automated job hunter is now running! 🎉

You'll receive daily emails with new job opportunities, complete with tailored resumes and cover letters for each position.

Happy job hunting! 🚀
