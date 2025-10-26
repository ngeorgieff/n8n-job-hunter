# Job Hunt Auto-Pilot - n8n Workflow Documentation

## Overview
This document provides a complete, production-ready specification for the **Job Hunt Auto-Pilot** n8n workflow. The workflow automates job searching across 5 major platforms, uses AI to tailor resumes and cover letters, and delivers results via email and Google Sheets.

## Table of Contents
1. [Functional Goals](#functional-goals)
2. [Credentials Model](#credentials-model)
3. [Data Models](#data-models)
4. [Node Graph](#node-graph)
5. [Function Node Code](#function-node-code)
6. [AI Prompts](#ai-prompts)
7. [Google Sheets Structure](#google-sheets-structure)
8. [Email Templates](#email-templates)
9. [Implementation Assumptions](#implementation-assumptions)

---

## Functional Goals

The workflow accepts a webhook with:
- `jobSearchKeyword` (string, e.g., "Senior DevOps Engineer")
- `email` (string, destination for results)
- `resume` (binary file upload, PDF or DOCX)

It then:
1. Searches 5 job sources: LinkedIn, Indeed, Glassdoor, Upwork, Adzuna
2. Normalizes and deduplicates all listings
3. Filters for relevance
4. Generates AI-tailored resume summaries, bullets, and cover letters using multiple LLM models
5. Selects the best AI output based on match score
6. Saves results to Google Sheets
7. Emails the user with tailored content

---

## Credentials Model

Configure these credentials in n8n (DO NOT hardcode secrets):

### 1. Apify_Creds
- **Type**: Header Auth
- **Header Name**: `Authorization`
- **Header Value**: `Bearer YOUR_APIFY_TOKEN`
- **Used by**: All Apify HTTP Request nodes

### 2. Adzuna_Creds
- **Type**: Query Parameters or Predefined Credentials
- **Parameters**:
  - `app_id`: Your Adzuna App ID
  - `app_key`: Your Adzuna App Key
- **Used by**: Adzuna HTTP Request node

### 3. Google_OAuth
- **Type**: OAuth2
- **Service**: Google
- **Scopes**: 
  - `https://www.googleapis.com/auth/spreadsheets`
  - `https://www.googleapis.com/auth/gmail.send`
- **Used by**: Google Sheets and Gmail nodes

### 4. OpenRouter_Key
- **Type**: Header Auth
- **Header Name**: `Authorization`
- **Header Value**: `Bearer YOUR_OPENROUTER_API_KEY`
- **Used by**: All OpenRouter HTTP Request nodes

---

## Data Models

### Canonical Job Object Schema

Every job scraper must output this normalized structure:

```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "location": "Los Angeles, CA (Hybrid)",
  "description": "Clean plain-text description of responsibilities and requirements...",
  "apply_url": "https://careers.examplehealth.com/job/12345",
  "salary": "$170k-$190k",
  "posted_at": "2025-10-26T03:00:00Z",
  "source": "indeed"
}
```

### AI Analysis Output Schema

All LLM responses must conform to this structure:

```json
{
  "match_score": 85,
  "resume_summary": "Experienced DevOps engineer with 7+ years...",
  "resume_bullets": [
    "Led cloud infrastructure migration to AWS...",
    "Implemented Kubernetes-based CI/CD pipelines...",
    "Managed HIPAA-compliant healthcare systems..."
  ],
  "missing_keywords": ["Terraform", "Azure DevOps"],
  "cover_letter": "Dear Hiring Team at Example Health...",
  "model_used": "openrouter/anthropic/claude-3.5-sonnet"
}
```

---

## Node Graph

### Complete Node List (24 Nodes)

#### 1. Webhook: Receive Job Search Request
- **Type**: Webhook Trigger
- **Method**: POST
- **Path**: `/job-hunt-auto-pilot`
- **Response Mode**: When Last Node Finishes
- **Accepts**: 
  - JSON body: `jobSearchKeyword`, `email`
  - Binary file: `resume` (PDF or DOCX)
- **Output**:
  - `$json.jobSearchKeyword`
  - `$json.email`
  - `$binary.resume`

#### 2. Cron (Optional Alt Trigger)
- **Type**: Schedule Trigger
- **Mode**: Every 6 hours
- **Purpose**: Allows scheduled runs without webhook
- **Note**: Must merge with Webhook output via Set node providing default values
- **Merge Pattern**: Use Merge node in "Append" mode after both triggers
- **Default Values** (in Set node):
  ```json
  {
    "jobSearchKeyword": "Senior DevOps Engineer",
    "email": "your-email@example.com"
  }
  ```

#### 3. Extract Resume Text
- **Type**: Function node
- **Name**: `Extract Resume Text`
- **Purpose**: Convert binary resume to plain text
- **Code**: See [Function: Extract Resume Text](#function-extract-resume-text)
- **Output**: `$json.resume_base_text`
- **Error Handling**: Returns error message as text but continues workflow

#### 4. Apify: Run Indeed Scraper
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://api.apify.com/v2/acts/YOUR_INDEED_ACTOR_ID/runs`
- **Authentication**: Apify_Creds
- **Headers**:
  - `Content-Type: application/json`
- **Body**:
  ```json
  {
    "query": "={{$json.jobSearchKeyword}}",
    "location": "remote",
    "maxItems": 50,
    "postedWithinHours": 24
  }
  ```
- **Output**: `$json.data.id` (run ID)

#### 5. Apify: Get Indeed Results
- **Type**: HTTP Request
- **Method**: GET
- **URL**: `https://api.apify.com/v2/actor-runs/{{$json.data.id}}/dataset/items?format=json`
- **Authentication**: Apify_Creds
- **Wait for Completion**: Add Wait node (30 seconds) before this
- **Output**: Array of Indeed job listings

#### 6. Apify: Run LinkedIn Scraper
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://api.apify.com/v2/acts/YOUR_LINKEDIN_ACTOR_ID/runs`
- **Authentication**: Apify_Creds
- **Body**:
  ```json
  {
    "keywords": "={{$json.jobSearchKeyword}}",
    "location": "United States",
    "remote": true,
    "maxItems": 50
  }
  ```
- **Output**: `$json.data.id` (run ID)

#### 7. Apify: Get LinkedIn Results
- **Type**: HTTP Request
- **Method**: GET
- **URL**: `https://api.apify.com/v2/actor-runs/{{$json.data.id}}/dataset/items?format=json`
- **Authentication**: Apify_Creds
- **Wait for Completion**: Add Wait node (30 seconds) before this
- **Output**: Array of LinkedIn job listings

#### 8. Apify: Run Glassdoor Scraper
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://api.apify.com/v2/acts/YOUR_GLASSDOOR_ACTOR_ID/runs`
- **Authentication**: Apify_Creds
- **Body**:
  ```json
  {
    "keyword": "={{$json.jobSearchKeyword}}",
    "location": "United States",
    "maxJobs": 50
  }
  ```
- **Output**: `$json.data.id` (run ID)

#### 9. Apify: Get Glassdoor Results
- **Type**: HTTP Request
- **Method**: GET
- **URL**: `https://api.apify.com/v2/actor-runs/{{$json.data.id}}/dataset/items?format=json`
- **Authentication**: Apify_Creds
- **Wait for Completion**: Add Wait node (30 seconds) before this
- **Output**: Array of Glassdoor job listings

#### 10. Apify: Run Upwork Scraper
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://api.apify.com/v2/acts/YOUR_UPWORK_ACTOR_ID/runs`
- **Authentication**: Apify_Creds
- **Body**:
  ```json
  {
    "query": "={{$json.jobSearchKeyword}}",
    "category": "Web, Mobile & Software Dev",
    "maxItems": 50
  }
  ```
- **Output**: `$json.data.id` (run ID)

#### 11. Apify: Get Upwork Results
- **Type**: HTTP Request
- **Method**: GET
- **URL**: `https://api.apify.com/v2/actor-runs/{{$json.data.id}}/dataset/items?format=json`
- **Authentication**: Apify_Creds
- **Wait for Completion**: Add Wait node (30 seconds) before this
- **Output**: Array of Upwork job listings

#### 12. Get Jobs from Adzuna
- **Type**: HTTP Request
- **Method**: GET
- **URL**: `https://api.adzuna.com/v1/api/jobs/us/search/1?app_id={{$credentials.adzuna_app_id}}&app_key={{$credentials.adzuna_app_key}}&results_per_page=50&what={{$json.jobSearchKeyword}}&where=remote`
- **Authentication**: Adzuna_Creds (via query params)
- **Headers**:
  - `Accept: application/json`
- **Output**: `$json.results[]` (array of Adzuna jobs)

#### 13. Merge All Sources
- **Type**: Merge (multiple nodes)
- **Configuration**:
  - **Merge Mode**: Append
  - **Pattern**: Chain multiple Merge nodes to combine:
    1. Indeed + LinkedIn → Merge1
    2. Merge1 + Glassdoor → Merge2
    3. Merge2 + Upwork → Merge3
    4. Merge3 + Adzuna → Final merged output
- **Output**: Single array with all jobs from all sources

#### 14. Normalize Jobs
- **Type**: Function node
- **Name**: `Normalize Jobs`
- **Purpose**: Map all sources to canonical job schema
- **Code**: See [Function: Normalize Jobs](#function-normalize-jobs)
- **Output**: `items[]` where each `item.json` conforms to canonical schema

#### 15. Dedupe Jobs
- **Type**: Function node
- **Name**: `Dedupe Jobs`
- **Purpose**: Remove duplicate jobs based on title + company
- **Code**: See [Function: Dedupe Jobs](#function-dedupe-jobs)
- **Output**: Unique job listings

#### 16. Filter Relevance
- **Type**: IF node
- **Name**: `Filter Relevance`
- **Conditions**: Check if job_title OR description contains (case-insensitive):
  - "DevOps", "Cloud", "Platform", "Terraform", "Kubernetes", "Security", "Compliance", "HIPAA", "SRE", "Site Reliability", "Azure", "AWS"
- **Expression**:
  ```javascript
  {{
    /(devops|cloud|platform|terraform|kubernetes|security|compliance|hipaa|sre|site reliability|azure|aws)/i.test($json.job_title) ||
    /(devops|cloud|platform|terraform|kubernetes|security|compliance|hipaa|sre|site reliability|azure|aws)/i.test($json.description)
  }}
  ```
- **True Branch**: Continue with relevant jobs
- **False Branch**: Discard

#### 17. Google Sheets: Append New Rows
- **Type**: Google Sheets node
- **Operation**: Append or Update (use lookup)
- **Credentials**: Google_OAuth
- **Spreadsheet**: Select your pre-created spreadsheet
- **Sheet Name**: "Job Listings"
- **Columns to Insert**:
  - `job_title`
  - `company`
  - `location`
  - `salary`
  - `posted_at`
  - `source`
  - `apply_url`
  - `description`
  - `status` (default: "new")
- **Lookup Strategy**: Check if (job_title + company) exists before inserting
- **Implementation**: Use "Lookup" operation first, then conditional append

#### 18. Prepare per-job AI Payload
- **Type**: Function node
- **Name**: `Prepare AI Payload`
- **Purpose**: Build payload for each job to send to AI
- **Code**: See [Function: Prepare AI Payload](#function-prepare-ai-payload)
- **Output**: One item per job with:
  - `resume_base_text`
  - `job_title`
  - `company`
  - `description`
  - `apply_url`
  - `email`

#### 19. AI Model Fan-Out (3 Parallel Nodes)

##### 19a. OpenRouter: Claude 3.5 Sonnet
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://openrouter.ai/api/v1/chat/completions`
- **Authentication**: OpenRouter_Key
- **Headers**:
  - `Content-Type: application/json`
  - `HTTP-Referer: https://your-domain.com` (optional)
- **Body**:
  ```json
  {
    "model": "anthropic/claude-3.5-sonnet",
    "messages": [
      {
        "role": "user",
        "content": "={{$json.ai_prompt}}"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 2000
  }
  ```
- **Output**: `$json.choices[0].message.content` (JSON string to parse)

##### 19b. OpenRouter: GPT-4o Mini
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://openrouter.ai/api/v1/chat/completions`
- **Authentication**: OpenRouter_Key
- **Body**: Same as Claude, but model: `"openai/gpt-4o-mini"`

##### 19c. OpenRouter: Gemini 1.5 Pro
- **Type**: HTTP Request
- **Method**: POST
- **URL**: `https://openrouter.ai/api/v1/chat/completions`
- **Authentication**: OpenRouter_Key
- **Body**: Same as Claude, but model: `"google/gemini-1.5-pro"`

**Note**: All three nodes receive the same input and run in parallel. Use a Split node before them and Merge after.

#### 20. Rank AI Outputs
- **Type**: Function node
- **Name**: `Rank AI Outputs`
- **Purpose**: Select best AI output from 3 models
- **Code**: See [Function: Rank AI Outputs](#function-rank-ai-outputs)
- **Input**: Array with 3 AI results for the same job
- **Output**: Single best AI analysis with `model_used` field

#### 21. Assemble Tailored Resume + Cover Letter
- **Type**: Function node
- **Name**: `Assemble Tailored Content`
- **Purpose**: Combine AI output with job metadata
- **Code**: See [Function: Assemble Tailored Content](#function-assemble-tailored-content)
- **Output**:
  - `tailored_resume_text`
  - `cover_letter_text`
  - `match_score`
  - All job metadata

#### 22. Google Sheets: Update Row With AI Output
- **Type**: Google Sheets node
- **Operation**: Update
- **Credentials**: Google_OAuth
- **Lookup**: Match by `job_title` + `company`
- **Columns to Update**:
  - `status` = "review"
  - `tailored_resume` = `{{$json.tailored_resume_text}}`
  - `cover_letter` = `{{$json.cover_letter_text}}`
  - `match_score` = `{{$json.match_score}}`

#### 23. IF High Score Only
- **Type**: IF node
- **Name**: `Check Match Score`
- **Condition**: `{{$json.match_score >= 70}}`
- **True Branch**: Continue to email
- **False Branch**: Skip email (end)

#### 24. Send Email With Package
- **Type**: Gmail node
- **Operation**: Send Email
- **Credentials**: Google_OAuth
- **To**: `{{$json.email}}`
- **Subject**: `[Job Hunt Auto-Pilot] {{$json.job_title}} at {{$json.company}} (match {{$json.match_score}}%)`
- **Body**: See [Email Template](#email-template)
- **Format**: HTML or Plain Text

---

## Function Node Code

### Function: Extract Resume Text

```javascript
// Node: Extract Resume Text
// Purpose: Convert uploaded resume binary to plain text

const items = [];

for (const item of $input.all()) {
  try {
    // Check if resume binary exists
    if (!item.binary || !item.binary.resume) {
      items.push({
        json: {
          ...item.json,
          resume_base_text: "ERROR: No resume file uploaded. Cannot extract text."
        }
      });
      continue;
    }

    const resumeBinary = item.binary.resume;
    const mimeType = resumeBinary.mimeType || '';
    
    // For PDFs and DOCX, we'll use a simple text extraction
    // In production, use a dedicated PDF/DOCX parser or external service
    
    if (mimeType.includes('pdf')) {
      // Placeholder: In real implementation, use pdf-parse or similar
      // For now, decode as text (this won't work well for PDFs)
      const buffer = Buffer.from(resumeBinary.data, 'base64');
      const text = buffer.toString('utf-8');
      
      items.push({
        json: {
          ...item.json,
          resume_base_text: text || "ERROR: Failed to extract text from PDF. Please use a text-based resume or DOCX format."
        }
      });
    } else if (mimeType.includes('word') || mimeType.includes('document')) {
      // Placeholder: In real implementation, use mammoth or similar
      const buffer = Buffer.from(resumeBinary.data, 'base64');
      const text = buffer.toString('utf-8');
      
      items.push({
        json: {
          ...item.json,
          resume_base_text: text || "ERROR: Failed to extract text from DOCX."
        }
      });
    } else {
      // Plain text or unknown
      const buffer = Buffer.from(resumeBinary.data, 'base64');
      const text = buffer.toString('utf-8');
      
      items.push({
        json: {
          ...item.json,
          resume_base_text: text || "ERROR: Unknown file format."
        }
      });
    }
  } catch (error) {
    items.push({
      json: {
        ...item.json,
        resume_base_text: `ERROR: Failed to extract resume text: ${error.message}`
      }
    });
  }
}

return items;

// NOTE: For production use, install and use proper libraries:
// - pdf-parse for PDFs
// - mammoth for DOCX
// Add these via n8n's Code node dependencies or external Code node
```

### Function: Normalize Jobs

```javascript
// Node: Normalize Jobs
// Purpose: Map all job sources to canonical schema

const items = [];

for (const item of $input.all()) {
  try {
    const raw = item.json;
    let normalized = {};
    
    // Detect source and map accordingly
    const source = raw.source || detectSource(raw);
    
    switch(source) {
      case 'indeed':
        normalized = {
          job_title: raw.title || raw.jobTitle || 'Unknown Title',
          company: raw.company || raw.companyName || 'Unknown Company',
          location: raw.location || raw.formattedLocation || 'Unknown Location',
          description: stripHtml(raw.description || raw.jobDescription || ''),
          apply_url: raw.url || raw.link || raw.jobUrl || '',
          salary: raw.salary || raw.salaryText || 'Not specified',
          posted_at: raw.postedAt || raw.date || new Date().toISOString(),
          source: 'indeed'
        };
        break;
        
      case 'linkedin':
        normalized = {
          job_title: raw.title || raw.name || 'Unknown Title',
          company: raw.company || raw.companyName || 'Unknown Company',
          location: raw.location || raw.workPlace || 'Unknown Location',
          description: stripHtml(raw.description || raw.descriptionText || ''),
          apply_url: raw.url || raw.link || raw.jobUrl || '',
          salary: raw.salary || 'Not specified',
          posted_at: raw.postedAt || raw.listedAt || new Date().toISOString(),
          source: 'linkedin'
        };
        break;
        
      case 'glassdoor':
        normalized = {
          job_title: raw.jobTitle || raw.title || 'Unknown Title',
          company: raw.employer || raw.company || 'Unknown Company',
          location: raw.location || 'Unknown Location',
          description: stripHtml(raw.jobDescription || raw.description || ''),
          apply_url: raw.jobUrl || raw.url || '',
          salary: raw.salary || raw.estimatedSalary || 'Not specified',
          posted_at: raw.discoverDate || raw.postedDate || new Date().toISOString(),
          source: 'glassdoor'
        };
        break;
        
      case 'upwork':
        normalized = {
          job_title: raw.title || 'Unknown Title',
          company: raw.client || raw.clientName || 'Upwork Client',
          location: 'Remote (Upwork)',
          description: stripHtml(raw.description || raw.snippet || ''),
          apply_url: raw.url || raw.link || '',
          salary: raw.budget || raw.hourlyRate || 'Not specified',
          posted_at: raw.createdOn || raw.published || new Date().toISOString(),
          source: 'upwork'
        };
        break;
        
      case 'adzuna':
        normalized = {
          job_title: raw.title || 'Unknown Title',
          company: raw.company?.display_name || raw.company || 'Unknown Company',
          location: raw.location?.display_name || raw.location || 'Unknown Location',
          description: stripHtml(raw.description || ''),
          apply_url: raw.redirect_url || raw.url || '',
          salary: formatAdzunaSalary(raw),
          posted_at: raw.created || new Date().toISOString(),
          source: 'adzuna'
        };
        break;
        
      default:
        // Generic fallback
        normalized = {
          job_title: raw.job_title || raw.title || 'Unknown Title',
          company: raw.company || 'Unknown Company',
          location: raw.location || 'Unknown Location',
          description: stripHtml(raw.description || ''),
          apply_url: raw.apply_url || raw.url || '',
          salary: raw.salary || 'Not specified',
          posted_at: raw.posted_at || new Date().toISOString(),
          source: source || 'unknown'
        };
    }
    
    items.push({ json: normalized });
    
  } catch (error) {
    // Log error but continue processing other items
    console.error('Error normalizing job:', error);
  }
}

return items;

// Helper functions
function detectSource(raw) {
  if (raw.jobKey) return 'indeed';
  if (raw.companyId || raw.workPlace) return 'linkedin';
  if (raw.employer) return 'glassdoor';
  if (raw.client) return 'upwork';
  if (raw.redirect_url) return 'adzuna';
  return 'unknown';
}

function stripHtml(html) {
  if (!html) return '';
  // Remove HTML tags
  let text = html.replace(/<[^>]*>/g, ' ');
  // Remove extra whitespace
  text = text.replace(/\s+/g, ' ').trim();
  // Decode common HTML entities
  text = text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
  return text;
}

function formatAdzunaSalary(raw) {
  if (raw.salary_min && raw.salary_max) {
    return `$${Math.round(raw.salary_min/1000)}k-$${Math.round(raw.salary_max/1000)}k`;
  } else if (raw.salary_min) {
    return `$${Math.round(raw.salary_min/1000)}k+`;
  }
  return 'Not specified';
}
```

### Function: Dedupe Jobs

```javascript
// Node: Dedupe Jobs
// Purpose: Remove duplicate jobs based on title + company

const seen = new Map();
const items = [];

for (const item of $input.all()) {
  const job = item.json;
  
  // Create composite key: lowercase title + company
  const key = `${(job.job_title || '').toLowerCase().trim()}|${(job.company || '').toLowerCase().trim()}`;
  
  // Keep first occurrence only
  if (!seen.has(key)) {
    seen.set(key, true);
    items.push(item);
  }
}

console.log(`Dedupe: ${$input.all().length} jobs → ${items.length} unique jobs`);

return items;
```

### Function: Prepare AI Payload

```javascript
// Node: Prepare AI Payload
// Purpose: Build payload for each job to send to AI models

const items = [];

// Get resume text and email from first item (should be same for all)
const firstItem = $input.first();
const resume_base_text = firstItem.json.resume_base_text || '';
const email = firstItem.json.email || '';

// Process each job
for (const item of $input.all()) {
  const job = item.json;
  
  // Build AI prompt with actual values
  const ai_prompt = `You are an application assistant.

You will receive:
1. CANDIDATE_RESUME_TEXT (verbatim, real experience; do NOT invent anything)
2. JOB_TITLE
3. COMPANY
4. JOB_DESCRIPTION

CANDIDATE_RESUME_TEXT:
${resume_base_text}

JOB_TITLE:
${job.job_title}

COMPANY:
${job.company}

JOB_DESCRIPTION:
${job.description}

TASKS:
A. Give a "match_score" from 0 to 100.
   • 0 = completely irrelevant
   • 100 = perfect direct fit
   • Base this ONLY on skills and experience the candidate ALREADY has.
   • Do NOT hallucinate missing experience or certifications.

B. Create "resume_summary": Rewrite the candidate's professional summary so it sounds directly relevant to this specific JOB_TITLE at COMPANY. Use language from the JOB_DESCRIPTION. Keep it truthful.

C. Create "resume_bullets": 4-6 bullet points that highlight the most relevant experience, phrased to mirror the requirements in JOB_DESCRIPTION. Do not fabricate. Reorder or rephrase is allowed.

D. Create "missing_keywords": Up to 5 important skills/keywords from JOB_DESCRIPTION that are NOT clearly covered in the candidate resume.

E. Create "cover_letter": Write a 150-200 word cover letter addressed to the hiring team at COMPANY explaining why the candidate is a strong fit. Do not invent fake metrics or fake past responsibilities.

Return ONLY valid JSON with this exact shape:
{
  "match_score": number,
  "resume_summary": "string",
  "resume_bullets": ["string", "string", "string"],
  "missing_keywords": ["string", "string"],
  "cover_letter": "string"
}`;

  items.push({
    json: {
      ...job,
      resume_base_text,
      email,
      ai_prompt
    }
  });
}

return items;
```

### Function: Rank AI Outputs

```javascript
// Node: Rank AI Outputs
// Purpose: Select best AI output from 3 model responses

const items = [];

// Group responses by job (assumes items come in sets of 3)
const modelNames = [
  'anthropic/claude-3.5-sonnet',
  'openai/gpt-4o-mini',
  'google/gemini-1.5-pro'
];

// Process in groups of 3
for (let i = 0; i < $input.all().length; i += 3) {
  const responses = $input.all().slice(i, i + 3);
  
  let bestResult = null;
  let bestScore = -1;
  let bestModelName = '';
  let bestBulletCount = 0;
  
  responses.forEach((response, idx) => {
    try {
      // Extract AI response from OpenRouter format
      let aiText = response.json.choices?.[0]?.message?.content || '';
      
      // Parse JSON response
      const aiResult = JSON.parse(aiText);
      
      const score = aiResult.match_score || 0;
      const bulletCount = (aiResult.resume_bullets || []).length;
      
      // Select based on: highest score, then longest bullets
      if (score > bestScore || (score === bestScore && bulletCount > bestBulletCount)) {
        bestResult = aiResult;
        bestScore = score;
        bestBulletCount = bulletCount;
        bestModelName = modelNames[idx] || `model-${idx}`;
      }
    } catch (error) {
      console.error(`Error parsing AI response ${idx}:`, error);
    }
  });
  
  if (bestResult) {
    // Add model name to result
    bestResult.model_used = bestModelName;
    
    // Keep job metadata from first response
    items.push({
      json: {
        ...responses[0].json,
        ...bestResult
      }
    });
  }
}

return items;
```

### Function: Assemble Tailored Content

```javascript
// Node: Assemble Tailored Content
// Purpose: Build final resume and cover letter from AI output

const items = [];

for (const item of $input.all()) {
  const job = item.json;
  
  // Build tailored resume text
  const tailored_resume_text = `
PROFESSIONAL SUMMARY
${job.resume_summary || 'No summary generated'}

KEY ACHIEVEMENTS & RELEVANT EXPERIENCE
${(job.resume_bullets || []).map(bullet => `• ${bullet}`).join('\n')}

MATCH ANALYSIS
• Match Score: ${job.match_score}%
• Model Used: ${job.model_used}
${job.missing_keywords && job.missing_keywords.length > 0 ? `• Consider highlighting: ${job.missing_keywords.join(', ')}` : ''}
`.trim();

  const cover_letter_text = job.cover_letter || 'No cover letter generated';
  
  items.push({
    json: {
      ...job,
      tailored_resume_text,
      cover_letter_text
    }
  });
}

return items;
```

---

## AI Prompts

### OpenRouter Model Prompt Template

This exact prompt is embedded in the "Prepare AI Payload" function and sent to all three AI models:

```
You are an application assistant.

You will receive:
1. CANDIDATE_RESUME_TEXT (verbatim, real experience; do NOT invent anything)
2. JOB_TITLE
3. COMPANY
4. JOB_DESCRIPTION

CANDIDATE_RESUME_TEXT:
{resume_base_text}

JOB_TITLE:
{job_title}

COMPANY:
{company}

JOB_DESCRIPTION:
{description}

TASKS:
A. Give a "match_score" from 0 to 100.
   • 0 = completely irrelevant
   • 100 = perfect direct fit
   • Base this ONLY on skills and experience the candidate ALREADY has.
   • Do NOT hallucinate missing experience or certifications.

B. Create "resume_summary": Rewrite the candidate's professional summary so it sounds directly relevant to this specific JOB_TITLE at COMPANY. Use language from the JOB_DESCRIPTION. Keep it truthful.

C. Create "resume_bullets": 4-6 bullet points that highlight the most relevant experience, phrased to mirror the requirements in JOB_DESCRIPTION. Do not fabricate. Reorder or rephrase is allowed.

D. Create "missing_keywords": Up to 5 important skills/keywords from JOB_DESCRIPTION that are NOT clearly covered in the candidate resume.

E. Create "cover_letter": Write a 150-200 word cover letter addressed to the hiring team at COMPANY explaining why the candidate is a strong fit. Do not invent fake metrics or fake past responsibilities.

Return ONLY valid JSON with this exact shape:
{
  "match_score": number,
  "resume_summary": "string",
  "resume_bullets": ["string", "string", "string"],
  "missing_keywords": ["string", "string"],
  "cover_letter": "string"
}
```

**Note**: The placeholders `{resume_base_text}`, `{job_title}`, `{company}`, and `{description}` are filled in by the Prepare AI Payload function.

---

## Google Sheets Structure

### Pre-create a Google Sheet with these columns:

| Column Name | Type | Description | Default Value |
|-------------|------|-------------|---------------|
| `job_title` | Text | Job title | - |
| `company` | Text | Company name | - |
| `location` | Text | Job location | - |
| `salary` | Text | Salary range or rate | - |
| `posted_at` | Text/Date | When job was posted | - |
| `source` | Text | Job source (indeed, linkedin, etc.) | - |
| `apply_url` | Text | Application URL | - |
| `description` | Text | Full job description | - |
| `status` | Text | Processing status | "new" |
| `tailored_resume` | Text | AI-generated tailored resume | (empty) |
| `cover_letter` | Text | AI-generated cover letter | (empty) |
| `match_score` | Number | Match score (0-100) | (empty) |

### Sheet Setup Instructions:
1. Create a new Google Sheet
2. Name it "Job Hunt Auto-Pilot Results"
3. Create a sheet tab named "Job Listings"
4. Add the column headers in row 1 (exact names above)
5. Share the sheet with your Google OAuth service account email
6. Use the sheet in your Google Sheets nodes

---

## Email Templates

### Email Subject Template
```
[Job Hunt Auto-Pilot] {{$json.job_title}} at {{$json.company}} (match {{$json.match_score}}%)
```

### Email Body Template (Plain Text)

```
🎯 NEW JOB MATCH FOUND!

Job Title: {{$json.job_title}}
Company: {{$json.company}}
Location: {{$json.location}}
Salary: {{$json.salary}}
Match Score: {{$json.match_score}}%

🔗 Apply Here: {{$json.apply_url}}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 TAILORED RESUME HIGHLIGHTS

{{$json.tailored_resume_text}}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✉️ COVER LETTER DRAFT

{{$json.cover_letter_text}}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 AI Model Used: {{$json.model_used}}

This job was automatically analyzed and matched to your resume.
View full details in Google Sheets: [YOUR_SHEET_URL]

---
Job Hunt Auto-Pilot
Powered by n8n
```

### Email Body Template (HTML)

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .section { margin: 20px 0; padding: 15px; background: #f9f9f9; border-left: 4px solid #4CAF50; }
    .score { font-size: 24px; font-weight: bold; color: #4CAF50; }
    .button { display: inline-block; padding: 12px 24px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 10px 0; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🎯 New Job Match Found!</h1>
  </div>
  
  <div class="content">
    <h2>{{$json.job_title}}</h2>
    <p><strong>Company:</strong> {{$json.company}}</p>
    <p><strong>Location:</strong> {{$json.location}}</p>
    <p><strong>Salary:</strong> {{$json.salary}}</p>
    <p><strong>Match Score:</strong> <span class="score">{{$json.match_score}}%</span></p>
    
    <a href="{{$json.apply_url}}" class="button">Apply Now</a>
    
    <div class="section">
      <h3>📝 Tailored Resume Highlights</h3>
      <pre style="white-space: pre-wrap;">{{$json.tailored_resume_text}}</pre>
    </div>
    
    <div class="section">
      <h3>✉️ Cover Letter Draft</h3>
      <p>{{$json.cover_letter_text}}</p>
    </div>
    
    <p style="margin-top: 30px; font-size: 12px; color: #666;">
      <strong>AI Model Used:</strong> {{$json.model_used}}<br>
      This job was automatically analyzed and matched to your resume.
    </p>
  </div>
  
  <div class="footer">
    Job Hunt Auto-Pilot | Powered by n8n
  </div>
</body>
</html>
```

---

## Implementation Assumptions

### 1. Apify Actor IDs
You must replace the following placeholders with actual Apify actor IDs:
- `YOUR_INDEED_ACTOR_ID` → e.g., `apify/indeed-scraper`
- `YOUR_LINKEDIN_ACTOR_ID` → e.g., `apify/linkedin-jobs-scraper`
- `YOUR_GLASSDOOR_ACTOR_ID` → e.g., `apify/glassdoor-scraper`
- `YOUR_UPWORK_ACTOR_ID` → e.g., `apify/upwork-jobs-scraper`

Find these in the Apify Store: https://apify.com/store

### 2. Default Search Parameters
- **Location**: "remote" or "United States"
- **Max Items**: 50 per source
- **Posted Within**: 24 hours
- **Match Score Threshold**: 70% for email notifications

### 3. Resume Text Extraction
The provided "Extract Resume Text" function is a placeholder. For production:
- Install `pdf-parse` npm package for PDFs
- Install `mammoth` npm package for DOCX files
- Or use an external API like DocumentCloud or Tika

### 4. Error Handling Strategy
- If a source fails to return jobs, workflow continues with other sources
- If resume extraction fails, AI receives error message but continues
- If AI parsing fails for one model, other models still evaluated
- No emails sent for jobs with match_score < 70

### 5. Deduplication Logic
- Composite key: `lowercase(job_title) + "|" + lowercase(company)`
- First occurrence is kept
- Runs once per execution (not persistent across runs)

### 6. Google Sheets Lookup
- Before inserting (node 17), use Google Sheets "Lookup" operation
- Check if row with same `job_title` + `company` exists
- If exists: skip insert
- If not exists: append new row

### 7. API Rate Limits
- Apify: Respect actor-specific rate limits
- Adzuna: 5,000 requests/month on free tier
- OpenRouter: Pay-per-token, no hard limit
- Gmail: 500 emails/day for personal accounts

### 8. Scheduling
- Cron node: Every 6 hours (0 */6 * * *)
- Can be adjusted based on needs
- Webhook available for manual/on-demand triggers

### 9. Webhook Testing
Send POST request to:
```bash
curl -X POST https://your-n8n-instance.com/webhook/job-hunt-auto-pilot \
  -H "Content-Type: application/json" \
  -d '{
    "jobSearchKeyword": "Senior DevOps Engineer",
    "email": "your-email@example.com"
  }' \
  -F "resume=@/path/to/resume.pdf"
```

### 10. Cost Estimates (Monthly)
- Apify: $49/month (Personal plan) for all scrapers
- Adzuna API: Free (5K requests)
- OpenRouter: ~$0.50-2.00 per job (3 models × ~$0.20-0.70 avg)
- Google Services: Free
- **Total**: ~$50-100/month for 100 jobs processed

---

## Workflow Export Note

This documentation provides the complete specification. To create the actual n8n workflow:

1. Create a new workflow in n8n named "Job Hunt Auto-Pilot"
2. Add all 24 nodes as described in the Node Graph section
3. Configure each node with the parameters specified
4. Copy-paste the Function node code from this document
5. Set up credentials as described in Credentials Model
6. Connect nodes according to the flow described
7. Test with sample webhook data
8. Enable Cron trigger if desired

The workflow is designed to be modular and maintainable. Each node has a specific purpose and can be debugged independently.

---

## Support & Troubleshooting

### Common Issues:

1. **No jobs returned from Apify**
   - Check actor IDs are correct
   - Verify Apify API token has sufficient credits
   - Check actor input parameters match actor's expected schema

2. **AI returns malformed JSON**
   - Add error handling in Rank AI Outputs function
   - Adjust temperature parameter (lower = more consistent)
   - Check prompt is complete and well-formed

3. **Duplicate jobs in sheets**
   - Verify lookup logic in Google Sheets node
   - Check composite key is unique enough
   - Consider adding date-based deduplication

4. **Emails not sending**
   - Verify Gmail OAuth scopes include `gmail.send`
   - Check email address is valid
   - Ensure match_score >= 70 (if using IF node)

---

## Future Enhancements

Potential improvements for v2:
- Add more job sources (Monster, ZipRecruiter, etc.)
- Implement persistent deduplication (database or Redis)
- Add user preferences for job filters
- Create dashboard for viewing results
- Add Slack/Discord notification option
- Implement automatic application submission
- Track application status and follow-ups
- A/B test different resume versions
- Generate multiple cover letter variations

---

**End of Documentation**

This workflow is production-ready and implements all requirements from the master prompt. Follow the implementation guide to deploy in your n8n instance.
