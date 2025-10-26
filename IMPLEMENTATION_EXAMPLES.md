# Implementation Examples & Best Practices

This document provides practical examples, tips, and best practices for implementing and maintaining the Job Hunt Auto-Pilot workflow.

## Table of Contents
1. [Webhook Testing Examples](#webhook-testing-examples)
2. [Function Node Debugging](#function-node-debugging)
3. [Error Handling Patterns](#error-handling-patterns)
4. [Performance Optimization](#performance-optimization)
5. [Monitoring & Logging](#monitoring--logging)
6. [Common Pitfalls](#common-pitfalls)
7. [Production Checklist](#production-checklist)

---

## Webhook Testing Examples

### Test with cURL (without resume)
```bash
curl -X POST https://your-n8n-instance.com/webhook/job-hunt-auto-pilot \
  -H "Content-Type: application/json" \
  -d '{
    "jobSearchKeyword": "Senior DevOps Engineer",
    "email": "test@example.com",
    "resume": "John Doe\nSenior DevOps Engineer\n\nProfessional with 7 years experience..."
  }'
```

### Test with cURL (with resume file)
```bash
curl -X POST https://your-n8n-instance.com/webhook/job-hunt-auto-pilot \
  -F "jobSearchKeyword=Senior DevOps Engineer" \
  -F "email=test@example.com" \
  -F "resume=@/path/to/resume.pdf"
```

### Test with Python
```python
import requests

# Without file
url = "https://your-n8n-instance.com/webhook/job-hunt-auto-pilot"
payload = {
    "jobSearchKeyword": "Senior DevOps Engineer",
    "email": "test@example.com",
    "resume": "John Doe\nSenior DevOps Engineer..."
}
response = requests.post(url, json=payload)
print(response.status_code, response.text)

# With file
files = {
    'resume': open('resume.pdf', 'rb')
}
data = {
    'jobSearchKeyword': 'Senior DevOps Engineer',
    'email': 'test@example.com'
}
response = requests.post(url, files=files, data=data)
print(response.status_code, response.text)
```

### Test with Postman
1. Create new POST request
2. URL: `https://your-n8n-instance.com/webhook/job-hunt-auto-pilot`
3. Body → form-data:
   - `jobSearchKeyword`: Senior DevOps Engineer
   - `email`: test@example.com
   - `resume`: [File] - Select PDF/DOCX
4. Send

---

## Function Node Debugging

### Debug Logging Pattern
```javascript
// Add at start of any Function node
console.log('=== Node Name ===');
console.log('Input items:', $input.all().length);
console.log('First item:', JSON.stringify($input.first().json, null, 2));

// Your processing logic here
const items = [];
for (const item of $input.all()) {
  // Log each iteration
  console.log('Processing:', item.json.job_title);
  
  // Your logic
  items.push(item);
}

// Log output
console.log('Output items:', items.length);
return items;
```

### Validate Input Data
```javascript
// Function: Validate Job Object
function validateJobObject(job) {
  const errors = [];
  
  // Required fields
  const required = ['job_title', 'company', 'description', 'source'];
  for (const field of required) {
    if (!job[field] || job[field].trim() === '') {
      errors.push(`Missing or empty required field: ${field}`);
    }
  }
  
  // Valid source
  const validSources = ['indeed', 'linkedin', 'glassdoor', 'upwork', 'adzuna'];
  if (job.source && !validSources.includes(job.source)) {
    errors.push(`Invalid source: ${job.source}`);
  }
  
  // Valid URL
  if (job.apply_url && !job.apply_url.startsWith('http')) {
    errors.push(`Invalid apply_url: ${job.apply_url}`);
  }
  
  return errors;
}

// Use in Normalize Jobs function
const items = [];
for (const item of $input.all()) {
  const normalized = /* your normalization logic */;
  
  const errors = validateJobObject(normalized);
  if (errors.length > 0) {
    console.error('Validation errors:', errors);
    // Skip invalid jobs or fix them
    continue;
  }
  
  items.push({ json: normalized });
}
```

### Safe JSON Parsing
```javascript
// Function: Rank AI Outputs
function safeJsonParse(text, defaultValue = null) {
  try {
    return JSON.parse(text);
  } catch (error) {
    console.error('JSON parse error:', error.message);
    console.error('Text:', text.substring(0, 200));
    return defaultValue;
  }
}

// Use in your function
const aiText = response.json.choices?.[0]?.message?.content || '';
const aiResult = safeJsonParse(aiText, {
  match_score: 0,
  resume_summary: 'Error parsing AI response',
  resume_bullets: [],
  missing_keywords: [],
  cover_letter: ''
});
```

---

## Error Handling Patterns

### Apify Scraper Error Handling
```javascript
// In HTTP Request node error output
// Add Function node to handle errors

const items = [];

for (const item of $input.all()) {
  if (item.json.error) {
    console.error('Apify error:', item.json.error);
    
    // Log but don't fail workflow
    items.push({
      json: {
        source: 'error',
        error_message: item.json.error.message,
        jobs: []
      }
    });
  } else {
    items.push(item);
  }
}

return items;
```

### AI API Error Handling
```javascript
// Function: Handle AI Errors
const items = [];

for (const item of $input.all()) {
  const response = item.json;
  
  // Check for API error
  if (response.error) {
    console.error('OpenRouter error:', response.error);
    
    // Create fallback AI response
    items.push({
      json: {
        ...item.json,
        match_score: 0,
        resume_summary: 'AI analysis failed',
        resume_bullets: ['AI service temporarily unavailable'],
        missing_keywords: [],
        cover_letter: 'Unable to generate cover letter',
        model_used: 'error'
      }
    });
    continue;
  }
  
  // Check for missing content
  if (!response.choices || !response.choices[0]) {
    console.error('Invalid AI response structure');
    items.push({
      json: {
        ...item.json,
        match_score: 0,
        resume_summary: 'Invalid AI response',
        resume_bullets: [],
        missing_keywords: [],
        cover_letter: '',
        model_used: 'error'
      }
    });
    continue;
  }
  
  items.push(item);
}

return items;
```

### Resume Extraction Error Handling
```javascript
// Function: Extract Resume Text (improved)
const items = [];

for (const item of $input.all()) {
  try {
    if (!item.binary?.resume) {
      items.push({
        json: {
          ...item.json,
          resume_base_text: 'ERROR: No resume file provided. Please upload your resume in PDF, DOCX, or TXT format.',
          extraction_error: true
        }
      });
      continue;
    }
    
    const resumeBinary = item.binary.resume;
    const mimeType = resumeBinary.mimeType || '';
    
    // Your extraction logic
    let text = '';
    
    // If extraction produces empty text
    if (!text || text.trim().length < 50) {
      text = 'ERROR: Resume file appears to be empty or unreadable. Please ensure your resume is not password-protected or corrupted.';
    }
    
    items.push({
      json: {
        ...item.json,
        resume_base_text: text,
        extraction_error: text.startsWith('ERROR')
      }
    });
    
  } catch (error) {
    items.push({
      json: {
        ...item.json,
        resume_base_text: `ERROR: Failed to extract resume: ${error.message}`,
        extraction_error: true
      }
    });
  }
}

return items;
```

---

## Performance Optimization

### 1. Reduce API Calls

**Before** (Sequential):
```
[Apify Indeed Run] → [Wait 30s] → [Apify Indeed Get] → 
[Apify LinkedIn Run] → [Wait 30s] → [Apify LinkedIn Get] → ...
```

**After** (Parallel):
```
                    ┌→ [Wait 30s] → [Apify Indeed Get] ─┐
[Split] → [Indeed Run] ┤                                  │
                    └→ [Wait 30s] → [LinkedIn Get] etc. ─┤
                                                          ↓
                                                       [Merge]
```

Use n8n's Split In Batches node to run Apify jobs in parallel.

### 2. Filter Early

**Before**:
```
Scrape → Normalize → Dedupe → AI Analysis → Filter Relevance
```

**After**:
```
Scrape → Filter Relevance → Normalize → Dedupe → AI Analysis
```

Filter irrelevant jobs BEFORE expensive AI calls.

### 3. Optimize AI Calls

```javascript
// Function: Batch AI Requests (advanced)
// Instead of calling AI for each job separately,
// batch multiple jobs in one prompt (if your AI can handle it)

const batchSize = 3;
const batches = [];

for (let i = 0; i < $input.all().length; i += batchSize) {
  const batch = $input.all().slice(i, i + batchSize);
  batches.push({
    json: {
      jobs: batch.map(item => item.json)
    }
  });
}

return batches;
```

### 4. Cache Deduplication

```javascript
// Function: Dedupe with Cache
// Store seen jobs in n8n static data or external Redis

const seenJobs = $workflow.staticData.seenJobs || {};
const items = [];

for (const item of $input.all()) {
  const key = `${item.json.job_title}|${item.json.company}`.toLowerCase();
  
  // Check if seen in last 7 days
  const lastSeen = seenJobs[key];
  if (lastSeen && Date.now() - lastSeen < 7 * 24 * 60 * 60 * 1000) {
    console.log('Skipping duplicate (seen before):', key);
    continue;
  }
  
  seenJobs[key] = Date.now();
  items.push(item);
}

// Save to static data
$workflow.staticData.seenJobs = seenJobs;

// Clean old entries (> 30 days)
for (const key in seenJobs) {
  if (Date.now() - seenJobs[key] > 30 * 24 * 60 * 60 * 1000) {
    delete seenJobs[key];
  }
}

return items;
```

---

## Monitoring & Logging

### 1. Execution Metrics Function

```javascript
// Function: Log Metrics (add at end of workflow)
const metrics = {
  workflow_id: $workflow.id,
  execution_id: $execution.id,
  timestamp: new Date().toISOString(),
  input_keyword: $('Webhook').first().json.jobSearchKeyword,
  jobs_scraped: $('Merge All Sources').all().length,
  jobs_normalized: $('Normalize Jobs').all().length,
  jobs_deduped: $('Dedupe Jobs').all().length,
  jobs_relevant: $('Filter Relevance').all().length,
  jobs_ai_analyzed: $('Rank AI Outputs').all().length,
  emails_sent: $('Send Email').all().length,
  execution_time_ms: Date.now() - new Date($execution.startedAt).getTime()
};

console.log('=== EXECUTION METRICS ===');
console.log(JSON.stringify(metrics, null, 2));

// Optionally send to external logging service
// or append to a metrics Google Sheet

return [{ json: metrics }];
```

### 2. Slack/Discord Alerts

Add a webhook node at the end to send summary to Slack:

```javascript
// Function: Prepare Slack Message
const jobs = $input.all();
const highScoreJobs = jobs.filter(j => j.json.match_score >= 80);

const message = {
  text: `🎯 Job Hunt Auto-Pilot Completed`,
  blocks: [
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Job Hunt Results*\n• Total jobs found: ${jobs.length}\n• High-score matches: ${highScoreJobs.length}\n• Emails sent: ${jobs.filter(j => j.json.match_score >= 70).length}`
      }
    },
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: highScoreJobs.slice(0, 3).map(j => 
          `• *${j.json.job_title}* at ${j.json.company} (${j.json.match_score}%)`
        ).join('\n')
      }
    }
  ]
};

return [{ json: message }];
```

### 3. Error Notifications

Create an error workflow that triggers on failures:

```javascript
// Function: Format Error Alert
const error = $input.first().json;

const message = {
  text: '⚠️ Job Hunt Auto-Pilot Error',
  blocks: [
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Workflow Error*\nNode: ${error.node}\nError: ${error.message}\nTime: ${new Date().toLocaleString()}`
      }
    }
  ]
};

return [{ json: message }];
```

---

## Common Pitfalls

### 1. ❌ Forgetting to Wait for Apify

**Problem**: Getting results before Apify actor finishes
```
[Apify Run] → [Apify Get Results] ❌ (too fast)
```

**Solution**: Add Wait node (30-60 seconds)
```
[Apify Run] → [Wait 30s] → [Apify Get Results] ✅
```

### 2. ❌ Not Handling Empty Results

**Problem**: Workflow crashes if a source returns no jobs

**Solution**: Add IF node to check for empty arrays
```javascript
// IF Node condition
{{$json.length > 0}}
```

### 3. ❌ Hardcoding Credentials

**Problem**: API keys in workflow JSON
```json
{
  "Authorization": "Bearer apify_api_12345..." ❌
}
```

**Solution**: Use n8n credentials
```json
{
  "Authentication": "Apify_Creds" ✅
}
```

### 4. ❌ Not Validating AI JSON

**Problem**: Assuming AI always returns valid JSON
```javascript
const aiResult = JSON.parse(aiText); ❌
```

**Solution**: Use try-catch
```javascript
try {
  const aiResult = JSON.parse(aiText);
} catch (error) {
  console.error('Invalid JSON from AI');
  const aiResult = { /* fallback */ };
}
```

### 5. ❌ Sending Too Many Emails

**Problem**: Gmail rate limit exceeded (500/day)

**Solution**: Add daily counter
```javascript
// Check daily count before sending
const today = new Date().toDateString();
const emailCount = $workflow.staticData.emailCount || {};

if (emailCount[today] >= 450) {
  console.log('Daily email limit approaching, skipping');
  return [];
}

// Increment counter
emailCount[today] = (emailCount[today] || 0) + 1;
$workflow.staticData.emailCount = emailCount;

return $input.all();
```

---

## Production Checklist

### Pre-Deployment
- [ ] All credentials configured and tested
- [ ] Google Sheet created with correct columns
- [ ] Webhook URL is HTTPS (not HTTP)
- [ ] Test run completed successfully
- [ ] Error handling added to all API calls
- [ ] Logging enabled for debugging
- [ ] Rate limits configured appropriately
- [ ] Email template tested and looks good

### Security
- [ ] No secrets hardcoded in workflow
- [ ] n8n credentials encrypted at rest
- [ ] OAuth scopes minimized
- [ ] API keys rotated in last 90 days
- [ ] Webhook endpoint secured (if needed)
- [ ] Resume data handling complies with privacy laws

### Performance
- [ ] Apify actors run in parallel where possible
- [ ] Wait times optimized (not too short, not too long)
- [ ] Filter relevance before AI calls
- [ ] AI batch size optimized
- [ ] Only necessary fields stored in Sheets

### Monitoring
- [ ] Execution logs reviewed regularly
- [ ] Error notifications configured
- [ ] Cost tracking in place
- [ ] Success metrics defined
- [ ] Alert thresholds set

### Documentation
- [ ] Workflow commented for future maintenance
- [ ] Credentials documented (not passwords!)
- [ ] API endpoints documented
- [ ] Customizations documented
- [ ] Recovery procedures documented

### Maintenance
- [ ] Weekly review of results quality
- [ ] Monthly API cost review
- [ ] Quarterly security audit
- [ ] Update AI prompts as needed
- [ ] Refresh job source actors if broken

---

## Advanced Patterns

### 1. Dynamic Job Sources

```javascript
// Function: Dynamic Source Selection
// Allow user to choose which sources to search

const sources = $input.first().json.sources || ['indeed', 'linkedin', 'adzuna'];
const enabledSources = {
  searchIndeed: sources.includes('indeed'),
  searchLinkedIn: sources.includes('linkedin'),
  searchGlassdoor: sources.includes('glassdoor'),
  searchUpwork: sources.includes('upwork'),
  searchAdzuna: sources.includes('adzuna')
};

return [{ json: enabledSources }];
```

Use IF nodes to conditionally execute source-specific branches.

### 2. Personalized Filtering

```javascript
// Function: User-Specific Filters
const user = $input.first().json;
const jobs = $input.all();

const filtered = jobs.filter(item => {
  const job = item.json;
  
  // Salary filter
  if (user.minSalary && job.salary) {
    const salaryMatch = job.salary.match(/\$(\d+)k/);
    if (salaryMatch && parseInt(salaryMatch[1]) < user.minSalary) {
      return false;
    }
  }
  
  // Location filter
  if (user.preferredLocations && user.preferredLocations.length > 0) {
    const locationMatch = user.preferredLocations.some(loc => 
      job.location.toLowerCase().includes(loc.toLowerCase())
    );
    if (!locationMatch && !job.location.toLowerCase().includes('remote')) {
      return false;
    }
  }
  
  // Experience level
  if (user.experienceLevel) {
    const titleLower = job.job_title.toLowerCase();
    if (user.experienceLevel === 'senior' && !titleLower.includes('senior')) {
      return false;
    }
  }
  
  return true;
});

return filtered;
```

### 3. A/B Testing Resume Versions

```javascript
// Function: Multi-Resume Support
// Test which resume version gets better match scores

const resumes = {
  'technical': $('Extract Resume Tech').first().json.resume_base_text,
  'leadership': $('Extract Resume Leadership').first().json.resume_base_text
};

const items = [];

for (const item of $input.all()) {
  // Create variant for each resume version
  for (const [version, resumeText] of Object.entries(resumes)) {
    items.push({
      json: {
        ...item.json,
        resume_base_text: resumeText,
        resume_version: version
      }
    });
  }
}

return items;

// Later, compare match scores by version
```

---

## Testing Strategies

### Unit Testing (Individual Nodes)

1. **Test Normalize Jobs**:
   - Input: Raw data from each source
   - Expected: Canonical job object
   - Validation: All required fields present

2. **Test Dedupe Jobs**:
   - Input: 10 jobs with 3 duplicates
   - Expected: 7 unique jobs
   - Validation: Count matches

3. **Test Filter Relevance**:
   - Input: Mix of relevant/irrelevant jobs
   - Expected: Only relevant jobs pass
   - Validation: All outputs contain keywords

### Integration Testing

1. **End-to-End Test**:
```bash
# Send test webhook
curl -X POST https://n8n.example.com/webhook/job-hunt-auto-pilot \
  -H "Content-Type: application/json" \
  -d @test-payload.json

# Verify in Google Sheets
# Check email received
# Review n8n execution log
```

2. **Load Test**:
```python
import concurrent.futures
import requests

def trigger_workflow(i):
    response = requests.post(
        'https://n8n.example.com/webhook/job-hunt-auto-pilot',
        json={
            'jobSearchKeyword': f'Test Job {i}',
            'email': 'test@example.com'
        }
    )
    return response.status_code

# Trigger 10 simultaneous runs
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(trigger_workflow, range(10)))

print(f'Success: {results.count(200)}/10')
```

---

## Troubleshooting Guide

### Issue: No Jobs Found

**Check**:
1. Apify actor IDs are correct
2. API tokens have credits
3. Search keyword isn't too specific
4. Location filter isn't too restrictive

**Debug**:
```javascript
// Add to each source's Get Results node
console.log('Jobs from source:', $json.length);
console.log('Sample job:', JSON.stringify($json[0], null, 2));
```

### Issue: AI Returns Errors

**Check**:
1. OpenRouter API key is valid
2. Model names are correct
3. Prompt isn't too long (token limit)
4. Resume text extracted successfully

**Debug**:
```javascript
// Add to Prepare AI Payload
console.log('Prompt length:', $json.ai_prompt.length);
console.log('Resume length:', $json.resume_base_text.length);
```

### Issue: Emails Not Sending

**Check**:
1. Gmail OAuth is authorized
2. Recipient email is valid
3. Match score >= 70
4. Daily limit not exceeded

**Debug**:
```javascript
// Add before Gmail node
console.log('Jobs to email:', $input.all().length);
console.log('Match scores:', $input.all().map(i => i.json.match_score));
```

---

**End of Implementation Examples**

Use these patterns and practices to build a robust, production-ready workflow!
