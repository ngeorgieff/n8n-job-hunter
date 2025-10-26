# Workflow Visual Diagram

This document provides visual representations of the Job Hunt Auto-Pilot workflow for easier understanding.

## High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INPUT TRIGGERS                               │
│  ┌──────────────┐                        ┌──────────────┐           │
│  │   Webhook    │                        │  Cron (6h)   │           │
│  │  POST /job   │                        │  Schedule    │           │
│  └──────┬───────┘                        └──────┬───────┘           │
│         │                                       │                   │
│         └───────────────┬───────────────────────┘                   │
│                         ↓                                           │
│                  ┌──────────────┐                                   │
│                  │  Merge Both  │                                   │
│                  │   Triggers   │                                   │
│                  └──────┬───────┘                                   │
└─────────────────────────┼───────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      RESUME PROCESSING                               │
│                  ┌──────────────┐                                   │
│                  │   Extract    │                                   │
│                  │ Resume Text  │                                   │
│                  │  (PDF/DOCX)  │                                   │
│                  └──────┬───────┘                                   │
└─────────────────────────┼───────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      JOB SCRAPING (Parallel)                         │
│                                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐         │
│  │  Apify   │   │  Apify   │   │  Apify   │   │  Apify   │         │
│  │ Indeed   │   │ LinkedIn │   │Glassdoor │   │ Upwork   │         │
│  │ Run→Get  │   │ Run→Get  │   │ Run→Get  │   │ Run→Get  │         │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘         │
│       │              │              │              │                │
│       │              │              │              │   ┌──────────┐ │
│       │              │              │              │   │ Adzuna   │ │
│       │              │              │              │   │   API    │ │
│       │              │              │              │   │  Direct  │ │
│       │              │              │              │   └────┬─────┘ │
│       └──────────────┴──────────────┴──────────────┴────────┘       │
│                                 ↓                                   │
│                         ┌──────────────┐                            │
│                         │  Merge All   │                            │
│                         │   Sources    │                            │
│                         └──────┬───────┘                            │
└─────────────────────────────────┼───────────────────────────────────┘
                                  │
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    DATA PROCESSING PIPELINE                          │
│                                                                      │
│                         ┌──────────────┐                            │
│                         │  Normalize   │                            │
│                         │     Jobs     │                            │
│                         │ (Canonical)  │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │   Dedupe     │                            │
│                         │     Jobs     │                            │
│                         │ (Title+Co.)  │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │    Filter    │                            │
│                         │  Relevance   │                            │
│                         │  (Keywords)  │                            │
│                         └──────┬───────┘                            │
└─────────────────────────────────┼───────────────────────────────────┘
                                  │
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                       GOOGLE SHEETS STORAGE                          │
│                         ┌──────────────┐                            │
│                         │    Append    │                            │
│                         │  New Jobs    │                            │
│                         │  to Sheet    │                            │
│                         └──────┬───────┘                            │
└─────────────────────────────────┼───────────────────────────────────┘
                                  │
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      AI ANALYSIS (Parallel)                          │
│                         ┌──────────────┐                            │
│                         │   Prepare    │                            │
│                         │  AI Payload  │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │    Split     │                            │
│                         │  Per Job     │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│       ┌────────────────────────┼────────────────────────┐           │
│       │                        │                        │           │
│  ┌────▼─────┐          ┌───────▼──────┐         ┌──────▼────┐      │
│  │  Claude  │          │  GPT-4o-mini │         │  Gemini   │      │
│  │   3.5    │          │   OpenAI     │         │  1.5 Pro  │      │
│  │ Sonnet   │          │   OpenRouter │         │  Google   │      │
│  └────┬─────┘          └───────┬──────┘         └──────┬────┘      │
│       │                        │                        │           │
│       └────────────────────────┼────────────────────────┘           │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │  Merge AI    │                            │
│                         │   Results    │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │  Rank Best   │                            │
│                         │  AI Output   │                            │
│                         │ (Score+Qual) │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │  Assemble    │                            │
│                         │  Tailored    │                            │
│                         │Resume+Cover  │                            │
│                         └──────┬───────┘                            │
└─────────────────────────────────┼───────────────────────────────────┘
                                  │
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     FINAL OUTPUT DELIVERY                            │
│                         ┌──────────────┐                            │
│                         │    Update    │                            │
│                         │  Sheet Rows  │                            │
│                         │  (AI Data)   │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │ Filter High  │                            │
│                         │   Scores     │                            │
│                         │  (≥70%)      │                            │
│                         └──────┬───────┘                            │
│                                ↓                                    │
│                         ┌──────────────┐                            │
│                         │    Send      │                            │
│                         │    Gmail     │                            │
│                         │    Email     │                            │
│                         └──────────────┘                            │
└─────────────────────────────────────────────────────────────────────┘
```

## Detailed Node Connections

### Phase 1: Input & Resume Processing
```
[1. Webhook]────────────┐
                        ├──→ [3. Merge] ──→ [4. Extract Resume Text]
[2. Cron Schedule]──────┘
```

### Phase 2: Job Scraping (All Parallel)
```
[4. Extract Resume] ──→ [5. Split] ──┬──→ [6. Apify Indeed Run] ──→ [Wait 30s] ──→ [7. Apify Indeed Get]──┐
                                      ├──→ [8. Apify LinkedIn Run] ──→ [Wait 30s] ──→ [9. LinkedIn Get]────┤
                                      ├──→ [10. Apify Glassdoor Run] ──→ [Wait 30s] ──→ [11. Glassdoor Get]┤
                                      ├──→ [12. Apify Upwork Run] ──→ [Wait 30s] ──→ [13. Upwork Get]──────┤
                                      └──→ [14. Adzuna HTTP Request]──────────────────────────────────────┘
                                                                                                            │
                                                                                                            ↓
                                                                                                    [15. Merge All]
```

### Phase 3: Data Processing
```
[15. Merge All] ──→ [16. Normalize Jobs] ──→ [17. Dedupe Jobs] ──→ [18. Filter Relevance (IF)]
                                                                            │
                                                                            ├──→ (True) ──→ Continue
                                                                            └──→ (False) ──→ End
```

### Phase 4: Storage & AI Prep
```
[18. Filter] ──→ [19. Google Sheets Append] ──→ [20. Prepare AI Payload] ──→ [21. Split Per Job]
```

### Phase 5: AI Analysis (Per Job, 3 Models Parallel)
```
[21. Split Per Job] ──┬──→ [22a. OpenRouter Claude] ──┐
                      ├──→ [22b. OpenRouter GPT-4o] ───┤
                      └──→ [22c. OpenRouter Gemini] ───┘
                                                        │
                                                        ↓
                                             [23. Merge AI Results]
                                                        │
                                                        ↓
                                              [24. Rank AI Outputs]
                                                        │
                                                        ↓
                                           [25. Assemble Tailored Content]
```

### Phase 6: Final Output
```
[25. Assemble] ──→ [26. Google Sheets Update] ──→ [27. IF Score ≥ 70] ──→ (True) ──→ [28. Gmail Send]
                                                           │
                                                           └──→ (False) ──→ End
```

## Data Flow Example

### 1. Input
```json
{
  "jobSearchKeyword": "Senior DevOps Engineer",
  "email": "candidate@example.com",
  "resume": [binary file]
}
```

### 2. After Resume Extraction
```json
{
  "jobSearchKeyword": "Senior DevOps Engineer",
  "email": "candidate@example.com",
  "resume_base_text": "John Doe\nSenior DevOps Engineer\n..."
}
```

### 3. After Job Scraping (per source)
```json
[
  {"title": "DevOps Engineer", "company": "Tech Corp", "source": "indeed"},
  {"title": "Cloud Engineer", "company": "Cloud Inc", "source": "linkedin"},
  // ... ~250 total jobs from 5 sources
]
```

### 4. After Normalization
```json
[
  {
    "job_title": "DevOps Engineer",
    "company": "Tech Corp",
    "location": "San Francisco, CA",
    "description": "We are seeking...",
    "apply_url": "https://...",
    "salary": "$150k-$180k",
    "posted_at": "2025-10-26T08:00:00Z",
    "source": "indeed"
  },
  // ... all normalized to same schema
]
```

### 5. After Deduplication
```json
// ~150 unique jobs (removed ~100 duplicates)
```

### 6. After Filtering
```json
// ~50 relevant jobs (removed ~100 irrelevant)
```

### 7. After AI Analysis (per job)
```json
{
  "job_title": "Senior DevOps Engineer",
  "company": "Tech Corp",
  // ... job details
  "match_score": 85,
  "resume_summary": "Experienced DevOps engineer...",
  "resume_bullets": ["Led migration...", "Implemented CI/CD..."],
  "missing_keywords": ["Terraform", "Azure"],
  "cover_letter": "Dear Hiring Team...",
  "model_used": "anthropic/claude-3.5-sonnet"
}
```

### 8. Final Output (Email)
```
Subject: [Job Hunt Auto-Pilot] Senior DevOps Engineer at Tech Corp (match 85%)

Job Title: Senior DevOps Engineer
Company: Tech Corp
Match Score: 85%

[Tailored resume highlights...]
[Custom cover letter...]
```

## Node Type Legend

| Symbol | Node Type | Purpose |
|--------|-----------|---------|
| 🔔 | Trigger | Webhook or Cron |
| 🔗 | Merge | Combine data streams |
| ⚙️ | Function | Data processing |
| 🌐 | HTTP Request | API calls |
| ⏱️ | Wait | Pause execution |
| ❓ | IF | Conditional logic |
| 📊 | Google Sheets | Data storage |
| 📧 | Gmail | Email sending |
| 🤖 | AI | LLM processing |

## Execution Time Breakdown

```
Phase                   | Time      | % of Total
------------------------|-----------|------------
Triggers & Setup        | 0-2s      | 2%
Resume Extraction       | 1-3s      | 3%
Job Scraping (parallel) | 30-60s    | 50%
Data Processing         | 5-10s     | 8%
Google Sheets Append    | 2-5s      | 4%
AI Analysis (parallel)  | 20-40s    | 30%
Final Output            | 3-5s      | 3%
------------------------|-----------|------------
TOTAL                   | 61-125s   | 100%
```

Typical execution: **2-5 minutes** depending on number of jobs

## Parallel vs Sequential Processing

### Parallel Processing (✅ Optimized)
```
Start ─┬─ Indeed (30s) ──┐
       ├─ LinkedIn (30s) ─┤
       ├─ Glassdoor (30s) ┤─→ Total: 30s
       ├─ Upwork (30s) ───┤
       └─ Adzuna (5s) ────┘
```

### Sequential Processing (❌ Slow)
```
Start ─→ Indeed (30s) ─→ LinkedIn (30s) ─→ Glassdoor (30s) ─→ Upwork (30s) ─→ Adzuna (5s)
Total: 125s
```

**Optimization**: Parallel processing saves ~95 seconds (76% faster)

## Cost Breakdown per Run

```
Component               | Cost/Run  | % of Total
------------------------|-----------|------------
Apify Scrapers (4)      | $0.08     | 3%
Adzuna API             | $0.00     | 0%
OpenRouter AI (3 models)| $2.22     | 97%
Google Services         | $0.00     | 0%
------------------------|-----------|------------
TOTAL                   | ~$2.30    | 100%
```

**Key Insight**: AI analysis is 97% of the cost. Consider:
- Using only 1-2 models instead of 3
- Using cheaper models (GPT-4o-mini only)
- Pre-filtering more aggressively

## Error Handling Flow

```
API Call ──→ Success? ─┬─→ Yes ──→ Continue
                       └─→ No ───→ Log Error ──→ Return Empty/Fallback ──→ Continue

AI Call ──→ Valid JSON? ─┬─→ Yes ──→ Continue
                         └─→ No ──→ Log Error ──→ Return Default (0 score) ──→ Continue

Resume Extract ──→ Success? ─┬─→ Yes ──→ Continue
                              └─→ No ──→ Return Error Message ──→ Continue (degraded)
```

**Philosophy**: Never fail the entire workflow. Always continue with degraded functionality.

## Resource Usage

### Memory
- **Peak**: ~500MB (with 250 jobs loaded)
- **Average**: ~200MB

### Network
- **Outbound API Calls**: 15-20 per run
- **Data Transfer**: ~5-10 MB per run

### n8n Execution Queue
- **Single Run**: 1 execution slot
- **Parallel Jobs**: Uses sub-executions within same slot

## Scaling Considerations

### Current Capacity
- Max jobs per run: ~250
- Max AI analyses: ~50 (limited by cost)
- Max emails: 450/day (Gmail limit)

### To Scale Up
1. **More job sources**: Add 5-10 more platforms
2. **Larger batches**: Increase maxItems per source
3. **Multiple keywords**: Run for different job searches
4. **Database storage**: Replace Sheets with PostgreSQL
5. **Queue system**: Add Redis for deduplication across runs

### To Scale Down (Cost)
1. **Fewer sources**: Use only Indeed + Adzuna (free)
2. **Single AI model**: Remove 2 models
3. **Higher match threshold**: Only email 80%+ matches
4. **Weekly runs**: Change cron from 6h to weekly

---

**End of Visual Diagram**

Use these diagrams to understand the workflow structure and optimize for your needs.
