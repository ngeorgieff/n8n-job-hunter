# Troubleshooting Guide

Common issues and their solutions for the n8n Job Hunter workflow.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Credential Problems](#credential-problems)
3. [Workflow Execution Errors](#workflow-execution-errors)
4. [API Issues](#api-issues)
5. [Data Quality Problems](#data-quality-problems)
6. [Performance Issues](#performance-issues)

---

## Installation Issues

### n8n Won't Start

**Symptom**: Docker container exits immediately or npm start fails

**Solutions**:

```bash
# Check Docker logs
docker logs n8n

# Common issues:
# 1. Port 5678 already in use
docker ps -a | grep 5678
# Kill conflicting process or use different port:
docker run -d --name n8n -p 5679:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n

# 2. Permission issues
sudo chown -R $(whoami) ~/.n8n

# 3. Corrupted installation
docker rm n8n
docker pull n8nio/n8n:latest
# Restart container
```

### Cannot Access n8n UI

**Symptom**: Browser shows "Connection refused" or timeout

**Solutions**:

```bash
# 1. Verify n8n is running
docker ps | grep n8n
# or
ps aux | grep n8n

# 2. Check firewall
sudo ufw status
sudo ufw allow 5678

# 3. Try localhost alternatives
# Instead of http://localhost:5678
# Try: http://127.0.0.1:5678
# Or: http://0.0.0.0:5678

# 4. Check if port is open
netstat -tulpn | grep 5678
```

---

## Credential Problems

### Apify API Not Working

**Symptom**: "Unauthorized" or "Invalid token" errors

**Diagnostic Steps**:

```bash
# Test API token directly
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.apify.com/v2/acts

# Expected: JSON response with status 200
# If error: Token is invalid
```

**Solutions**:

1. **Regenerate Token**:
   - Go to Apify console → Account → Integrations
   - Generate new token
   - Update in n8n credentials

2. **Check Token Format**:
   - Should start with "apify_api_"
   - No extra spaces or quotes
   - In n8n, use: `Bearer YOUR_TOKEN`

3. **Verify Account Status**:
   - Free tier has limits
   - Check billing status
   - Verify email is confirmed

### Google OAuth Errors

**Symptom**: "OAuth consent screen error" or "Redirect URI mismatch"

**Solutions**:

1. **Fix Redirect URI**:
   ```
   Correct format:
   http://localhost:5678/rest/oauth2-credential/callback
   
   In Google Cloud Console:
   APIs & Services → Credentials → OAuth 2.0 Client IDs
   Add exact redirect URI from n8n credential screen
   ```

2. **Re-authorize**:
   ```
   In n8n:
   1. Go to Credentials
   2. Delete existing Google credential
   3. Create new one
   4. Copy exact redirect URI
   5. Add to Google Cloud Console
   6. Reconnect in n8n
   ```

3. **Check OAuth Consent Screen**:
   ```
   Required scopes:
   - https://www.googleapis.com/auth/spreadsheets
   - https://www.googleapis.com/auth/gmail.send
   
   Add your email as test user
   ```

### OpenRouter API Failures

**Symptom**: "Insufficient credits" or "Invalid API key"

**Diagnostic**:

```bash
# Test API key
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer YOUR_KEY"

# Check credits
# Login to openrouter.ai → Keys & Credits
```

**Solutions**:

1. **Add Credits**: Minimum $5 recommended
2. **Check Key Format**: Should start with "sk-"
3. **Verify Model Access**: Some models require approval
4. **Rate Limits**: Free tier is limited, upgrade if needed

---

## Workflow Execution Errors

### Workflow Fails at "Wait for Apify Results"

**Symptom**: Workflow hangs or times out

**Diagnostic**:

```javascript
// Add debug logging to "Wait for Apify Results" node
console.log('Run ID:', run.id);
console.log('Status:', status);
console.log('Attempts:', attempts);
```

**Solutions**:

1. **Increase Timeout**:
   ```javascript
   // In "Wait for Apify Results" node
   const maxAttempts = 60;  // Increase from 30
   const waitTime = 15000;  // Increase from 10000
   ```

2. **Check Apify Dashboard**:
   - Login to Apify
   - Check "Runs" tab
   - Look for failed or stuck runs
   - Check error messages

3. **Reduce Job Size**:
   ```javascript
   // In "Set Job Parameters"
   maxResults: "10"  // Reduce from 50
   ```

### "Merge All Results" Node Fails

**Symptom**: "Cannot merge empty arrays" or no data passing through

**Diagnostic**:

```javascript
// Add to "Normalize Job Data" node
console.log('Input items:', $input.all().length);
console.log('Sample item:', JSON.stringify($input.all()[0], null, 2));
```

**Solutions**:

1. **Check Individual Sources**:
   - Test each API node separately
   - Verify at least one source returns data
   - Disable problematic sources temporarily

2. **Handle Empty Results**:
   ```javascript
   // Add to merge logic
   if ($input.all().length === 0) {
     return [{ json: { message: "No jobs found" } }];
   }
   ```

### Google Sheets Update Fails

**Symptom**: "Sheet not found" or "Permission denied"

**Solutions**:

1. **Verify Sheet Setup**:
   ```
   Checklist:
   ☐ Sheet name is exactly "Jobs" (case-sensitive)
   ☐ First row has correct headers
   ☐ Sheet ID in environment variable is correct
   ☐ You have edit permissions
   ```

2. **Test Sheet Access**:
   ```javascript
   // Create a simple test workflow:
   // Set node → Google Sheets (append)
   // Add one row manually
   // If this works, issue is with main workflow
   ```

3. **Check Column Names**:
   ```
   Required columns (exact spelling):
   Title, Company, Location, Description, URL,
   Salary, Posted Date, Source, Status, Applied,
   Date Found, Tailored Resume, Cover Letter, AI Processed
   ```

### AI Processing Errors

**Symptom**: Jobs saved but no tailored resumes/cover letters

**Diagnostic**:

```javascript
// Add to "Process AI Response" node
console.log('AI Response:', JSON.stringify(job, null, 2));
console.log('Choices:', job.choices);
console.log('Content:', job.choices[0]?.message?.content);
```

**Solutions**:

1. **Check Resume/Cover Letter Variables**:
   ```bash
   # Verify environment variables are set
   docker exec -it n8n env | grep USER_RESUME
   docker exec -it n8n env | grep USER_COVER_LETTER
   ```

2. **Test AI Separately**:
   ```bash
   # Test OpenRouter API directly
   curl -X POST https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "openai/gpt-3.5-turbo",
       "messages": [
         {"role": "user", "content": "Hello"}
       ]
     }'
   ```

3. **Simplify AI Prompt**:
   ```javascript
   // Reduce token usage
   "max_tokens": 1000  // Reduce from 2000
   
   // Simplify prompt
   "content": "Tailor this resume for the job title: ${title}"
   ```

---

## API Issues

### Apify Rate Limits

**Symptom**: "Rate limit exceeded" errors

**Solutions**:

1. **Check Usage**:
   - Apify Console → Usage & Limits
   - Monitor run count

2. **Reduce Frequency**:
   ```json
   // In Schedule Trigger
   "interval": {
     "field": "days",
     "daysInterval": 2  // Run every 2 days instead
   }
   ```

3. **Upgrade Plan**:
   - Free: 100 runs/month
   - Starter: $49/month, unlimited runs
   - Check pricing at apify.com/pricing

### Adzuna API Limits

**Symptom**: "API call limit reached"

**Solutions**:

1. **Monitor Usage**:
   - Adzuna Dashboard → API Usage
   - Free tier: 1,000 calls/month

2. **Reduce Calls**:
   ```javascript
   // Only use Adzuna, disable Apify
   // Or reduce results_per_page
   ```

3. **Implement Caching**:
   ```javascript
   // Add caching logic to avoid repeated searches
   const cacheKey = `${keyword}-${location}`;
   if (cache.has(cacheKey)) {
     return cache.get(cacheKey);
   }
   ```

### OpenRouter Costs Too High

**Symptom**: Credits depleting quickly

**Solutions**:

1. **Switch to Cheaper Model**:
   ```json
   {
     "model": "openai/gpt-3.5-turbo"  // ~10x cheaper than GPT-4
   }
   ```

2. **Process Fewer Jobs**:
   ```javascript
   // Add filter before AI processing
   const topJobs = jobs.slice(0, 10);  // Only top 10 jobs
   ```

3. **Reduce Token Usage**:
   ```json
   {
     "max_tokens": 500,      // Reduce from 2000
     "temperature": 0.5      // More focused responses
   }
   ```

4. **Batch Processing**:
   ```javascript
   // Process jobs in batches instead of one-by-one
   const batch = jobs.slice(0, 5);
   // Single API call for multiple jobs
   ```

---

## Data Quality Problems

### Too Many Duplicate Jobs

**Symptom**: Same job appears multiple times

**Solutions**:

1. **Improve Deduplication**:
   ```javascript
   // More aggressive deduplication
   const uniqueId = `${job.title.toLowerCase()}-${job.company.toLowerCase()}`
     .replace(/[^a-z0-9]/g, '');
   ```

2. **Add Company Name Normalization**:
   ```javascript
   // Remove variations like "Inc.", "LLC", etc.
   const normalizedCompany = company
     .replace(/\b(inc|llc|corp|ltd)\b/gi, '')
     .trim();
   ```

3. **Use URL as Unique Key**:
   ```javascript
   // URLs are always unique
   const uniqueId = job.url;
   ```

### Job Descriptions Too Long

**Symptom**: Google Sheets cells truncated, AI costs high

**Solutions**:

1. **Truncate Descriptions**:
   ```javascript
   // In "Normalize Job Data"
   description: job.description.substring(0, 500) + '...'
   ```

2. **Extract Summary Only**:
   ```javascript
   // Use AI to summarize
   const summary = extractFirstParagraph(job.description);
   ```

### Missing Salary Information

**Symptom**: Most jobs show "Not specified"

**Solutions**:

1. **Add Salary Parsing**:
   ```javascript
   // Extract from description
   const salaryRegex = /\$[\d,]+\s*-?\s*\$?[\d,]*/g;
   const salaryMatch = description.match(salaryRegex);
   const salary = salaryMatch ? salaryMatch[0] : 'Not specified';
   ```

2. **Use AI to Extract**:
   ```javascript
   // Add to AI prompt
   "Also extract salary information if mentioned in the job description"
   ```

### Irrelevant Jobs

**Symptom**: Jobs don't match search criteria

**Solutions**:

1. **Add Keyword Filtering**:
   ```javascript
   // Filter by must-have keywords
   const requiredKeywords = ['python', 'react', 'senior'];
   const filtered = jobs.filter(job => 
     requiredKeywords.some(kw => 
       job.description.toLowerCase().includes(kw)
     )
   );
   ```

2. **Exclude Unwanted Terms**:
   ```javascript
   const excludeKeywords = ['manager', 'director', 'sales'];
   const filtered = jobs.filter(job =>
     !excludeKeywords.some(kw =>
       job.title.toLowerCase().includes(kw)
     )
   );
   ```

3. **Add Salary Filter**:
   ```javascript
   const minSalary = 80000;
   const filtered = jobs.filter(job => {
     const salary = parseInt(job.salary_min);
     return salary >= minSalary;
   });
   ```

---

## Performance Issues

### Workflow Takes Too Long

**Symptom**: Execution time > 30 minutes

**Diagnostic**:

```javascript
// Add timing to nodes
const startTime = Date.now();
// ... node logic ...
console.log(`Execution time: ${Date.now() - startTime}ms`);
```

**Solutions**:

1. **Optimize Apify Waits**:
   ```javascript
   // Reduce wait time for quick scrapers
   const waitTime = 5000;  // 5 seconds instead of 10
   ```

2. **Process in Parallel** (already configured):
   - All searches run simultaneously
   - No changes needed

3. **Reduce Data Processing**:
   ```javascript
   // Skip AI for low-priority jobs
   const topJobs = jobs
     .sort((a, b) => b.relevance - a.relevance)
     .slice(0, 20);
   ```

### High Memory Usage

**Symptom**: n8n crashes or becomes unresponsive

**Solutions**:

1. **Increase Docker Memory**:
   ```bash
   docker run -d --name n8n \
     --memory="2g" \
     --memory-swap="2g" \
     -p 5678:5678 \
     -v ~/.n8n:/home/node/.n8n \
     n8nio/n8n
   ```

2. **Process in Batches**:
   ```javascript
   // Instead of processing all jobs at once
   const batchSize = 10;
   for (let i = 0; i < jobs.length; i += batchSize) {
     const batch = jobs.slice(i, i + batchSize);
     // Process batch
   }
   ```

3. **Clear Old Executions**:
   ```bash
   # In n8n settings
   EXECUTIONS_DATA_PRUNE_MAX_AGE=7  # Keep only 7 days
   ```

### Database Growing Too Large

**Symptom**: Disk space issues

**Solutions**:

1. **Prune Executions**:
   ```bash
   # Add to .env
   EXECUTIONS_DATA_PRUNE=true
   EXECUTIONS_DATA_MAX_AGE=168  # 7 days in hours
   ```

2. **Use External Database**:
   ```bash
   # Switch to PostgreSQL
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=localhost
   DB_POSTGRESDB_DATABASE=n8n
   ```

3. **Archive Old Jobs**:
   ```javascript
   // Add workflow to archive jobs > 30 days old
   // Move to separate sheet or delete
   ```

---

## Email Issues

### Emails Not Received

**Symptom**: Workflow completes but no email

**Solutions**:

1. **Check Spam Folder**

2. **Verify Gmail Settings**:
   ```
   Gmail → Settings → Filters
   Ensure no filters are blocking automated emails
   ```

3. **Test Email Node**:
   ```javascript
   // Create simple test workflow
   // Manual trigger → Gmail send
   // Subject: "Test"
   // Body: "Hello"
   ```

4. **Check Gmail API Quota**:
   - Google Cloud Console → APIs & Services
   - Gmail API → Quotas
   - Default: 1 billion quota units/day (should be enough)

### Email Formatting Issues

**Symptom**: Broken HTML or plain text

**Solutions**:

1. **Verify Email Type**:
   ```json
   {
     "emailType": "html"  // Not "text"
   }
   ```

2. **Test HTML**:
   ```javascript
   // Validate HTML in online validator
   // Copy email body HTML
   // Test at validator.w3.org
   ```

3. **Simplify HTML**:
   ```javascript
   // Use basic HTML only
   // Avoid complex CSS
   // Use inline styles
   ```

---

## Getting Help

If you're still stuck:

1. **Check Logs**:
   ```bash
   # Docker logs
   docker logs n8n --tail 100
   
   # Workflow execution logs
   # In n8n: Executions → Click failed execution
   ```

2. **Enable Debug Mode**:
   ```bash
   # Add to .env
   N8N_LOG_LEVEL=debug
   ```

3. **Community Support**:
   - [n8n Community Forum](https://community.n8n.io/)
   - [n8n Discord](https://discord.gg/n8n)
   - [GitHub Issues](https://github.com/n8n-io/n8n/issues)

4. **Export Workflow for Help**:
   ```
   Workflows → ... → Download
   Share JSON (remove sensitive data first!)
   ```

5. **Create Minimal Reproduction**:
   - Simplify workflow to minimal failing case
   - Remove unrelated nodes
   - Share with support

---

## Prevention Best Practices

1. **Test Incrementally**: Test each node before running full workflow
2. **Monitor Regularly**: Check executions weekly
3. **Set Alerts**: Configure n8n to notify on failures
4. **Keep Backups**: Export workflow JSON regularly
5. **Document Changes**: Note what you modify
6. **Version Control**: Store workflow JSON in git
7. **Monitor Costs**: Check API usage dashboards monthly

---

## Quick Checklist for Common Issues

**Before Asking for Help**:

- [ ] Checked logs in n8n execution view
- [ ] Verified all credentials are valid
- [ ] Tested individual nodes in isolation
- [ ] Confirmed API keys have sufficient credits/quota
- [ ] Checked environment variables are set
- [ ] Verified Google Sheet is accessible
- [ ] Confirmed OAuth tokens haven't expired
- [ ] Reviewed recent n8n updates/changes
- [ ] Searched community forum for similar issues
- [ ] Created minimal reproduction of the issue

**Report Issues With**:

- n8n version
- Node.js version (if not using Docker)
- Operating system
- Error message (full text)
- Workflow JSON (sanitized)
- Steps to reproduce
- Expected vs actual behavior
