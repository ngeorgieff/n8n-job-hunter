# Workflow Architecture Diagram

This document provides a visual representation and detailed explanation of the n8n Job Hunter workflow architecture.

## Workflow Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         TRIGGER & INITIALIZATION                         │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │ Schedule Trigger │  ← Runs daily (configurable)
    │   (Every 1 day)  │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │ Set Job          │  ← Define search parameters:
    │ Parameters       │    - keyword, location, country, maxResults
    └────────┬─────────┘
             │
             │ (Splits into 5 parallel paths)
             │
┌────────────┴────────────────────────────────────────────────────────────┐
│                         PARALLEL JOB SEARCHES                            │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────┬─────────┬─────────┬─────────┬─────────┐
    │         │         │         │         │         │
    ▼         ▼         ▼         ▼         ▼         
┌────────┐┌────────┐┌────────┐┌────────┐┌─────────┐
│LinkedIn││Indeed  ││Glassdoor│Upwork  ││ Adzuna  │
│(Apify) ││(Apify) ││(Apify)  │(Apify) ││  API    │
└───┬────┘└───┬────┘└───┬────┘└───┬────┘└────┬────┘
    │         │         │         │          │
    │         │         │         │          │
    └────┬────┴────┬────┴────┬────┘          │
         │         │         │               │
         ▼         ▼         ▼               ▼
    ┌─────────────────────────┐    ┌──────────────────┐
    │ Wait for Apify Results  │    │ Process Adzuna   │
    │ (Polls until complete)  │    │ Results          │
    └───────────┬─────────────┘    └────────┬─────────┘
                │                           │
                └────────┬──────────────────┘
                         │
┌────────────────────────┴─────────────────────────────────────────────────┐
│                      DATA PROCESSING & STORAGE                            │
└───────────────────────────────────────────────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Merge All       │  ← Combines results from all sources
                │ Results         │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Normalize       │  ← Standardizes data format
                │ Job Data        │    (title, company, location, etc.)
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Deduplicate     │  ← Removes duplicate jobs
                │ Jobs            │    (based on title+company+location)
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Save to Google  │  ← Appends to "Jobs" sheet
                │ Sheets          │    (11 columns of data)
                └────────┬────────┘
                         │
┌────────────────────────┴─────────────────────────────────────────────────┐
│                      AI PROCESSING & CUSTOMIZATION                        │
└───────────────────────────────────────────────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Load User       │  ← Loads from environment:
                │ Documents       │    - Resume text
                └────────┬────────┘    - Cover letter template
                         │
                         ▼
                ┌─────────────────┐
                │ OpenRouter AI   │  ← Calls GPT-4 to:
                │ Tailor Docs     │    - Tailor resume for job
                └────────┬────────┘    - Write custom cover letter
                         │
                         ▼
                ┌─────────────────┐
                │ Process AI      │  ← Extracts tailored content
                │ Response        │    from JSON response
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Update Sheet    │  ← Adds AI content to sheet:
                │ with AI Content │    - Tailored Resume column
                └────────┬────────┘    - Cover Letter column
                         │
┌────────────────────────┴─────────────────────────────────────────────────┐
│                      NOTIFICATION & REPORTING                             │
└───────────────────────────────────────────────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Prepare Email   │  ← Creates HTML email with:
                │ Summary         │    - Total jobs found
                └────────┬────────┘    - Breakdown by source
                         │              - Top 10 jobs
                         │              - Link to sheet
                         ▼
                ┌─────────────────┐
                │ Send Gmail      │  ← Sends formatted email
                │ Summary         │    to recipient
                └─────────────────┘
                         │
                         ▼
                    [COMPLETE]
```

## Node Details by Stage

### Stage 1: Trigger & Initialization

| Node | Purpose | Key Configuration |
|------|---------|-------------------|
| **Schedule Trigger** | Starts workflow automatically | Interval: 1 day (customizable) |
| **Set Job Parameters** | Defines search criteria | keyword, location, country, maxResults |

### Stage 2: Parallel Job Searches

All five searches run **simultaneously** for maximum efficiency:

| Node | Platform | API Method | Results Expected |
|------|----------|------------|------------------|
| **Apify LinkedIn Jobs** | LinkedIn | Apify Actor | 10-50 jobs |
| **Apify Indeed Jobs** | Indeed | Apify Actor | 10-50 jobs |
| **Apify Glassdoor Jobs** | Glassdoor | Apify Actor | 10-50 jobs |
| **Apify Upwork Jobs** | Upwork | Apify Actor | 10-50 jobs |
| **Adzuna API Jobs** | Adzuna | REST API | 10-50 jobs |

**Total potential results**: 50-250 jobs (before deduplication)

### Stage 3: Data Processing & Storage

| Node | Input | Output | Processing |
|------|-------|--------|------------|
| **Wait for Apify Results** | 4 run IDs | Job arrays | Polls until complete (max 5 min) |
| **Process Adzuna Results** | API response | Normalized jobs | Extracts from `results` array |
| **Merge All Results** | 2 data streams | Combined array | Merges Apify + Adzuna |
| **Normalize Job Data** | Raw jobs | Standardized format | Maps to common schema |
| **Deduplicate Jobs** | All jobs | Unique jobs | Removes duplicates |
| **Save to Google Sheets** | Unique jobs | Sheet rows | Appends to "Jobs" sheet |

**Data flow**: 50-250 raw jobs → ~30-150 unique jobs

### Stage 4: AI Processing & Customization

| Node | Input | Output | AI Model |
|------|-------|--------|----------|
| **Load User Documents** | Environment vars | Resume + Template | N/A |
| **OpenRouter AI** | Job + Resume | Tailored content | GPT-4 Turbo |
| **Process AI Response** | API response | Extracted text | N/A |
| **Update Sheet** | AI content | Updated rows | N/A |

**Cost per job**: ~$0.01-0.05 (depending on model)

### Stage 5: Notification & Reporting

| Node | Input | Output | Format |
|------|-------|--------|--------|
| **Prepare Email Summary** | All jobs | HTML email | Styled HTML |
| **Send Gmail Summary** | Email data | Sent message | Gmail API |

## Data Schema Evolution

### Initial Job Data (from APIs)
```json
{
  "title": "Software Engineer",
  "company": "Tech Corp",
  "location": "San Francisco, CA",
  "description": "We are looking for...",
  "url": "https://...",
  "salary": "$120k-$180k",
  "posted_date": "2025-10-20",
  "source": "LinkedIn"
}
```

### After Normalization
```json
{
  "title": "Software Engineer",
  "company": "Tech Corp",
  "location": "San Francisco, CA",
  "description": "We are looking for...",
  "url": "https://...",
  "salary": "$120k-$180k",
  "posted_date": "2025-10-20",
  "source": "LinkedIn",
  "uniqueId": "software-engineer-tech-corp-san-francisco-ca"
}
```

### After AI Processing
```json
{
  "title": "Software Engineer",
  "company": "Tech Corp",
  "location": "San Francisco, CA",
  "description": "We are looking for...",
  "url": "https://...",
  "salary": "$120k-$180k",
  "posted_date": "2025-10-20",
  "source": "LinkedIn",
  "uniqueId": "software-engineer-tech-corp-san-francisco-ca",
  "tailored_resume": "JOHN DOE\nSoftware Engineer...",
  "cover_letter": "Dear Hiring Manager...",
  "ai_processed": true
}
```

### In Google Sheet
| Title | Company | Location | ... | Tailored Resume | Cover Letter | AI Processed |
|-------|---------|----------|-----|-----------------|--------------|--------------|
| Software Engineer | Tech Corp | San Francisco, CA | ... | JOHN DOE... | Dear Hiring Manager... | Yes |

## Execution Timeline

Typical execution times for each stage:

```
Stage 1: Trigger & Init           [0-5s]
    ↓
Stage 2: Parallel Searches        [30s-5m]
    ├─ Apify Jobs (waiting)       [1-5m per source]
    └─ Adzuna API                 [1-3s]
    ↓
Stage 3: Processing & Storage     [5-15s]
    ├─ Merge                      [<1s]
    ├─ Normalize                  [1-2s]
    ├─ Deduplicate                [1-2s]
    └─ Save to Sheets             [2-5s]
    ↓
Stage 4: AI Processing            [1-5m]
    ├─ Per job                    [2-10s each]
    └─ For 50 jobs                [1-5m total]
    ↓
Stage 5: Email                    [2-5s]

Total: 2-15 minutes (varies by job count)
```

## Error Handling

### Built-in Error Recovery

```
┌─────────────────┐
│ Apify Job Fails │
└────────┬────────┘
         │
         ▼
   [Skip Source]
         │
         ▼
┌─────────────────┐
│ Continue with   │
│ Other Sources   │
└─────────────────┘
```

### Retry Logic

- **Apify polling**: 30 attempts × 10 seconds = 5 minutes max
- **If timeout**: Returns empty array, continues workflow
- **If API error**: Logs error, continues with other sources

## Optimization Opportunities

### Performance Optimizations

1. **Parallel Processing** ✓ (Already implemented)
   - All searches run simultaneously
   - No sequential bottlenecks

2. **Batch AI Processing** (Possible enhancement)
   ```
   Current: Process each job individually
   Enhanced: Process 5-10 jobs per API call
   Benefit: Reduce API calls by 80-90%
   ```

3. **Caching** (Possible enhancement)
   ```
   Current: Search all sources every time
   Enhanced: Cache results for 6-12 hours
   Benefit: Reduce API costs by 50%
   ```

### Cost Optimizations

1. **Selective AI Processing** (Recommended)
   ```
   Current: Process all jobs with AI
   Enhanced: Only process top 20 jobs by relevance
   Savings: 60-80% of AI costs
   ```

2. **Cheaper AI Model** (Optional)
   ```
   Current: GPT-4 Turbo ($0.01/1K tokens)
   Alternative: GPT-3.5 Turbo ($0.0005/1K tokens)
   Savings: 95% of AI costs (with slight quality trade-off)
   ```

## Scalability Considerations

### Current Limits
- **Jobs per run**: ~30-150 (after deduplication)
- **Execution time**: 2-15 minutes
- **API calls**: ~5 per run
- **AI processing**: ~30-150 calls per run

### Scaling Options

**For more jobs**:
- Increase `maxResults` parameter (50 → 100)
- Add more job platforms
- Run multiple times per day

**For better performance**:
- Use n8n Queue Mode for distributed processing
- Implement job prioritization
- Add parallel AI processing

**For cost reduction**:
- Filter jobs before AI processing
- Use cheaper AI models
- Reduce search frequency

## Integration Points

### External Services

```
┌──────────────────────────────────────────────┐
│  External Service Dependencies               │
├──────────────────────────────────────────────┤
│  • Apify (Web Scraping)                      │
│  • Adzuna (Job API)                          │
│  • OpenRouter (AI)                           │
│  • Google Sheets (Storage)                   │
│  • Gmail (Notifications)                     │
└──────────────────────────────────────────────┘
```

### Environment Dependencies

```
Required Environment Variables:
├─ GOOGLE_SHEET_ID
├─ RECIPIENT_EMAIL
├─ USER_RESUME_TEXT
└─ USER_COVER_LETTER_TEMPLATE

Required Credentials (in n8n):
├─ Apify API (HTTP Header Auth)
├─ OpenRouter API (HTTP Header Auth)
├─ Google Sheets OAuth2
└─ Gmail OAuth2
```

## Monitoring & Observability

### Key Metrics to Track

1. **Success Rate**: % of successful executions
2. **Job Count**: Jobs found per execution
3. **Deduplication Rate**: % of duplicates removed
4. **AI Success Rate**: % of jobs successfully processed by AI
5. **Execution Time**: Total time per run
6. **API Costs**: Monthly spend on each service

### Logs to Review

- n8n execution logs (in UI)
- Apify run logs (in Apify console)
- Google Sheets activity log
- Email delivery status

---

## Next Steps

After understanding the workflow architecture:

1. ✅ Review the workflow JSON
2. ✅ Set up required credentials
3. ✅ Configure environment variables
4. ✅ Test individual nodes
5. ✅ Run full workflow test
6. ✅ Monitor first few executions
7. ✅ Optimize based on results

For detailed setup instructions, see [SETUP.md](SETUP.md).
