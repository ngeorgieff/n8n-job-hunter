# Job Hunt Auto-Pilot - Quick Start Guide

## Prerequisites

Before setting up the workflow, ensure you have:

1. **Self-hosted n8n instance** (v1.0+) running
2. **Apify account** with API token
3. **Google Cloud account** with OAuth2 configured
4. **OpenRouter API key** 
5. **Adzuna API credentials** (app_id and app_key)

## Setup Steps

### Step 1: Create Credentials in n8n

#### 1.1 Apify Credentials
1. In n8n, go to **Credentials** → **New Credential**
2. Select **Header Auth**
3. Name: `Apify_Creds`
4. Header Name: `Authorization`
5. Header Value: `Bearer YOUR_APIFY_TOKEN`
6. Save

#### 1.2 Adzuna Credentials
1. Create new credential: **Generic Credential Type**
2. Name: `Adzuna_Creds`
3. Add fields:
   - `app_id`: Your Adzuna App ID
   - `app_key`: Your Adzuna App Key
4. Save

#### 1.3 Google OAuth
1. Create new credential: **Google OAuth2 API**
2. Name: `Google_OAuth`
3. Follow n8n's Google OAuth setup wizard
4. Required scopes:
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/gmail.send`
5. Authorize and save

#### 1.4 OpenRouter Credentials
1. Create new credential: **Header Auth**
2. Name: `OpenRouter_Key`
3. Header Name: `Authorization`
4. Header Value: `Bearer YOUR_OPENROUTER_API_KEY`
5. Save

### Step 2: Create Google Sheet

1. Create a new Google Sheet
2. Name it: **Job Hunt Auto-Pilot Results**
3. Add a sheet tab named: **Job Listings**
4. Add these column headers in row 1:

```
job_title | company | location | salary | posted_at | source | apply_url | description | status | tailored_resume | cover_letter | match_score
```

5. Share the sheet with your Google service account email (from OAuth setup)
6. Copy the Sheet ID from the URL (the long string between `/d/` and `/edit`)

### Step 3: Find Apify Actor IDs

1. Go to [Apify Store](https://apify.com/store)
2. Search for and note the actor IDs for:
   - **Indeed Scraper**: e.g., `apify/indeed-scraper`
   - **LinkedIn Jobs Scraper**: e.g., `misceres/linkedin-jobs-scraper`
   - **Glassdoor Scraper**: e.g., `apify/glassdoor-scraper`
   - **Upwork Scraper**: Search for "upwork jobs"
3. Copy these IDs - you'll need them in Step 4

### Step 4: Create the Workflow

1. In n8n, click **Workflows** → **Add Workflow**
2. Name it: **Job Hunt Auto-Pilot**
3. Follow the node creation guide below

## Node Creation Guide

### Quick Setup Order:

1. **Add Webhook Trigger**
   - Path: `/job-hunt-auto-pilot`
   - Method: POST
   - Response: When Last Node Finishes

2. **Add Schedule Trigger** (optional)
   - Cron: `0 */6 * * *` (every 6 hours)

3. **Add Merge Node** (to combine Webhook + Cron)
   - Mode: Append

4. **Add Function Node: Extract Resume Text**
   - Copy code from WORKFLOW_DOCUMENTATION.md

5. **Add Apify Nodes** (8 nodes total: 4 Run + 4 Get Results)
   - Update actor IDs with your actual IDs from Step 3
   - Add Wait nodes (30s) between Run and Get

6. **Add HTTP Request: Adzuna**
   - URL with your credentials

7. **Add Merge Nodes** (chain to combine all sources)

8. **Add Function Nodes**:
   - Normalize Jobs
   - Dedupe Jobs
   - Prepare AI Payload
   - Rank AI Outputs
   - Assemble Tailored Content

9. **Add IF Node: Filter Relevance**

10. **Add Google Sheets: Append Rows**
    - Select your sheet from Step 2

11. **Add Split Node** (before AI calls)

12. **Add 3 HTTP Request Nodes** (parallel AI models)
    - Claude 3.5 Sonnet
    - GPT-4o Mini
    - Gemini 1.5 Pro

13. **Add Merge Node** (after AI calls)

14. **Add Google Sheets: Update Rows**

15. **Add IF Node: High Score Filter** (≥70)

16. **Add Gmail Node: Send Email**

### Connection Flow:

```
[Webhook] ─┐
           ├─→ [Merge] → [Extract Resume] → [Apify Indeed Run] → [Wait] → [Apify Indeed Get] ─┐
[Cron] ────┘                                                                                   │
                                                                                               │
[Apify LinkedIn Run] → [Wait] → [Apify LinkedIn Get] ─────────────────────────────────────────┤
[Apify Glassdoor Run] → [Wait] → [Apify Glassdoor Get] ───────────────────────────────────────┤
[Apify Upwork Run] → [Wait] → [Apify Upwork Get] ─────────────────────────────────────────────┤
[Adzuna HTTP] ─────────────────────────────────────────────────────────────────────────────────┤
                                                                                               │
                                                                                               ↓
→ [Merge All] → [Normalize] → [Dedupe] → [Filter IF] → [Sheets Append] → [Prepare AI] → [Split] ─┐
                                                                                                    │
[AI Claude] ←───────────────────────────────────────────────────────────────────────────────────────┤
[AI GPT] ←──────────────────────────────────────────────────────────────────────────────────────────┤
[AI Gemini] ←───────────────────────────────────────────────────────────────────────────────────────┘
    │
    └─→ [Merge AI] → [Rank AI] → [Assemble] → [Sheets Update] → [IF Score≥70] → [Gmail Send]
```

## Step 5: Test the Workflow

### Test with Webhook

1. Activate the workflow
2. Copy the webhook URL (shown in Webhook node)
3. Use curl or Postman to test:

```bash
curl -X POST https://your-n8n.com/webhook/job-hunt-auto-pilot \
  -H "Content-Type: application/json" \
  -d '{
    "jobSearchKeyword": "DevOps Engineer",
    "email": "your-email@example.com",
    "resume": "I am a DevOps engineer with 5 years experience..."
  }'
```

### Test with Manual Trigger

1. Click **Execute Workflow** button
2. In the Webhook node, click **Listen for Test Event**
3. Send test data
4. Monitor execution in n8n UI

### Verify Results

1. Check Google Sheets - should see new jobs added
2. Check email - should receive emails for high-scoring matches
3. Review n8n execution log for errors

## Step 6: Monitor & Maintain

### Daily Checks
- Review Google Sheets for new matches
- Check n8n execution history for errors
- Monitor Apify credit usage

### Weekly Tasks
- Review match quality and adjust filters
- Update AI prompt if needed
- Clean up old entries in Google Sheets

### Monthly Tasks
- Review API costs (Apify, OpenRouter)
- Optimize job sources based on quality
- Update resume base text if candidate's experience changes

## Troubleshooting

### No Jobs Found
- **Check**: Apify actor IDs are correct
- **Check**: API tokens have sufficient credits
- **Check**: Search keyword is not too specific

### AI Errors
- **Check**: OpenRouter API key is valid
- **Check**: Prompt is properly formatted
- **Check**: Resume text was extracted successfully

### Gmail Not Sending
- **Check**: OAuth scopes include `gmail.send`
- **Check**: Email address is valid
- **Check**: Match score is ≥70

### Duplicate Jobs
- **Check**: Dedupe function is running
- **Check**: Google Sheets lookup is working
- **Solution**: Clear sheet and re-run

## Cost Optimization Tips

1. **Reduce API calls**:
   - Lower `maxItems` in Apify calls
   - Increase `postedWithinHours` filter
   - Run less frequently (e.g., once daily)

2. **Optimize AI usage**:
   - Use cheaper models (GPT-4o-mini only)
   - Reduce to 1-2 models instead of 3
   - Add pre-filtering before AI calls

3. **Use free tier wisely**:
   - Adzuna: 5,000 calls/month free
   - Google: Unlimited sheets, 500 emails/day
   - Focus budget on Apify and OpenRouter

## Next Steps

Once your workflow is running smoothly:

1. **Customize filters** in the Filter Relevance node
2. **Add more job sources** (Monster, ZipRecruiter)
3. **Improve AI prompts** based on output quality
4. **Create dashboards** using Google Data Studio
5. **Set up alerts** for high-value matches
6. **Track application success** in Google Sheets

## Support Resources

- **n8n Documentation**: https://docs.n8n.io
- **Apify Docs**: https://docs.apify.com
- **OpenRouter API**: https://openrouter.ai/docs
- **Adzuna API**: https://developer.adzuna.com

## Important Notes

⚠️ **Resume Privacy**: Be cautious about sending resume text to external APIs. Ensure compliance with data privacy regulations.

⚠️ **API Costs**: Monitor usage closely, especially for OpenRouter (charged per token).

⚠️ **Rate Limits**: Respect API rate limits to avoid account suspension.

✅ **Best Practice**: Start with a small test (1-2 jobs) before running at scale.

---

**You're all set!** Your Job Hunt Auto-Pilot workflow is ready to help you find and tailor applications for the best jobs automatically.
