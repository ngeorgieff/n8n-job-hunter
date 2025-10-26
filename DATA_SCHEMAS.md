# Data Schemas for Job Hunt Auto-Pilot

This document contains all JSON schemas used in the workflow for validation and reference.

## 1. Webhook Input Schema

### Request Body
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["jobSearchKeyword", "email"],
  "properties": {
    "jobSearchKeyword": {
      "type": "string",
      "description": "Job title or keyword to search for",
      "example": "Senior DevOps Engineer",
      "minLength": 3,
      "maxLength": 100
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Email address to send results to",
      "example": "candidate@example.com"
    }
  }
}
```

### Binary File (Resume)
```json
{
  "resume": {
    "type": "binary",
    "mimeType": ["application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/plain"],
    "maxSize": "5MB"
  }
}
```

## 2. Canonical Job Object Schema

This is the normalized format that ALL job sources must be mapped to.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["job_title", "company", "description", "source"],
  "properties": {
    "job_title": {
      "type": "string",
      "description": "Job title",
      "example": "Senior Cloud DevOps Engineer"
    },
    "company": {
      "type": "string",
      "description": "Company name",
      "example": "Example Health"
    },
    "location": {
      "type": "string",
      "description": "Job location (city, state, remote status)",
      "example": "Los Angeles, CA (Hybrid)",
      "default": "Unknown Location"
    },
    "description": {
      "type": "string",
      "description": "Plain text job description (HTML stripped)",
      "minLength": 50
    },
    "apply_url": {
      "type": "string",
      "format": "uri",
      "description": "Direct application URL",
      "example": "https://careers.examplehealth.com/job/12345",
      "default": ""
    },
    "salary": {
      "type": "string",
      "description": "Salary range or hourly rate",
      "example": "$170k-$190k",
      "default": "Not specified"
    },
    "posted_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of when job was posted",
      "example": "2025-10-26T03:00:00Z"
    },
    "source": {
      "type": "string",
      "enum": ["indeed", "linkedin", "glassdoor", "upwork", "adzuna"],
      "description": "Job source platform"
    }
  }
}
```

## 3. AI Analysis Output Schema

This is the expected response from all AI models.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["match_score", "resume_summary", "resume_bullets", "missing_keywords", "cover_letter"],
  "properties": {
    "match_score": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100,
      "description": "Match score between candidate and job (0-100)",
      "example": 85
    },
    "resume_summary": {
      "type": "string",
      "description": "Tailored professional summary for this specific job",
      "minLength": 50,
      "maxLength": 500,
      "example": "Experienced DevOps engineer with 7+ years specializing in cloud infrastructure and HIPAA-compliant healthcare systems..."
    },
    "resume_bullets": {
      "type": "array",
      "description": "4-6 tailored bullet points highlighting relevant experience",
      "minItems": 4,
      "maxItems": 6,
      "items": {
        "type": "string",
        "minLength": 30,
        "maxLength": 200
      },
      "example": [
        "Led cloud infrastructure migration to AWS, reducing costs by 40%",
        "Implemented Kubernetes-based CI/CD pipelines serving 2M+ users",
        "Managed HIPAA-compliant healthcare systems with 99.99% uptime"
      ]
    },
    "missing_keywords": {
      "type": "array",
      "description": "Up to 5 important keywords from job description not found in resume",
      "maxItems": 5,
      "items": {
        "type": "string"
      },
      "example": ["Terraform", "Azure DevOps", "Splunk"]
    },
    "cover_letter": {
      "type": "string",
      "description": "Tailored cover letter (150-200 words)",
      "minLength": 150,
      "maxLength": 300,
      "example": "Dear Hiring Team at Example Health,\n\nI am excited to apply for the Senior DevOps Engineer position..."
    },
    "model_used": {
      "type": "string",
      "description": "AI model that generated this output (added by Rank AI Outputs node)",
      "enum": [
        "anthropic/claude-3.5-sonnet",
        "openai/gpt-4o-mini",
        "google/gemini-1.5-pro"
      ],
      "example": "anthropic/claude-3.5-sonnet"
    }
  }
}
```

## 4. Apify Actor Input Schemas

### Indeed Scraper
```json
{
  "query": "Senior DevOps Engineer",
  "location": "remote",
  "maxItems": 50,
  "postedWithinHours": 24
}
```

### LinkedIn Scraper
```json
{
  "keywords": "Senior DevOps Engineer",
  "location": "United States",
  "remote": true,
  "maxItems": 50
}
```

### Glassdoor Scraper
```json
{
  "keyword": "Senior DevOps Engineer",
  "location": "United States",
  "maxJobs": 50
}
```

### Upwork Scraper
```json
{
  "query": "Senior DevOps Engineer",
  "category": "Web, Mobile & Software Dev",
  "maxItems": 50
}
```

## 5. OpenRouter API Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["model", "messages"],
  "properties": {
    "model": {
      "type": "string",
      "enum": [
        "anthropic/claude-3.5-sonnet",
        "openai/gpt-4o-mini",
        "google/gemini-1.5-pro"
      ],
      "description": "AI model to use"
    },
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["role", "content"],
        "properties": {
          "role": {
            "type": "string",
            "enum": ["user", "assistant", "system"]
          },
          "content": {
            "type": "string",
            "description": "The AI prompt with job and resume details"
          }
        }
      }
    },
    "temperature": {
      "type": "number",
      "minimum": 0,
      "maximum": 2,
      "default": 0.7,
      "description": "Sampling temperature (0 = deterministic, 2 = very random)"
    },
    "max_tokens": {
      "type": "integer",
      "minimum": 1,
      "maximum": 4096,
      "default": 2000,
      "description": "Maximum tokens in response"
    }
  }
}
```

## 6. OpenRouter API Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique completion ID"
    },
    "model": {
      "type": "string",
      "description": "Model that generated the response"
    },
    "choices": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "index": {
            "type": "integer"
          },
          "message": {
            "type": "object",
            "properties": {
              "role": {
                "type": "string",
                "enum": ["assistant"]
              },
              "content": {
                "type": "string",
                "description": "AI-generated JSON response (must be parsed)"
              }
            }
          },
          "finish_reason": {
            "type": "string",
            "enum": ["stop", "length", "content_filter"]
          }
        }
      }
    },
    "usage": {
      "type": "object",
      "properties": {
        "prompt_tokens": {
          "type": "integer"
        },
        "completion_tokens": {
          "type": "integer"
        },
        "total_tokens": {
          "type": "integer"
        }
      }
    }
  }
}
```

## 7. Google Sheets Row Schema

### On Insert (Node 17)
```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "location": "Los Angeles, CA (Hybrid)",
  "salary": "$170k-$190k",
  "posted_at": "2025-10-26T03:00:00Z",
  "source": "indeed",
  "apply_url": "https://careers.examplehealth.com/job/12345",
  "description": "We are seeking an experienced DevOps engineer...",
  "status": "new",
  "tailored_resume": "",
  "cover_letter": "",
  "match_score": null
}
```

### On Update (Node 22)
```json
{
  "status": "review",
  "tailored_resume": "PROFESSIONAL SUMMARY\nExperienced DevOps engineer...",
  "cover_letter": "Dear Hiring Team at Example Health...",
  "match_score": 85
}
```

## 8. Gmail Email Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["to", "subject", "message"],
  "properties": {
    "to": {
      "type": "string",
      "format": "email",
      "description": "Recipient email address"
    },
    "subject": {
      "type": "string",
      "description": "Email subject line",
      "example": "[Job Hunt Auto-Pilot] Senior DevOps Engineer at Example Health (match 85%)"
    },
    "message": {
      "type": "string",
      "description": "Email body (plain text or HTML)",
      "minLength": 100
    },
    "cc": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "email"
      },
      "description": "CC recipients (optional)"
    },
    "bcc": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "email"
      },
      "description": "BCC recipients (optional)"
    }
  }
}
```

## 9. Internal Workflow Data Schemas

### After Extract Resume Text
```json
{
  "jobSearchKeyword": "Senior DevOps Engineer",
  "email": "candidate@example.com",
  "resume_base_text": "John Doe\nSenior DevOps Engineer\n\nPROFESSIONAL SUMMARY\n..."
}
```

### After Normalize Jobs
```json
[
  {
    "job_title": "Senior Cloud DevOps Engineer",
    "company": "Example Health",
    "location": "Los Angeles, CA (Hybrid)",
    "description": "Clean plain text description...",
    "apply_url": "https://careers.examplehealth.com/job/12345",
    "salary": "$170k-$190k",
    "posted_at": "2025-10-26T03:00:00Z",
    "source": "indeed"
  }
]
```

### After Prepare AI Payload
```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "description": "Clean plain text description...",
  "apply_url": "https://careers.examplehealth.com/job/12345",
  "resume_base_text": "John Doe\nSenior DevOps Engineer...",
  "email": "candidate@example.com",
  "ai_prompt": "You are an application assistant.\n\nYou will receive..."
}
```

### After Rank AI Outputs
```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "location": "Los Angeles, CA (Hybrid)",
  "description": "Clean plain text description...",
  "apply_url": "https://careers.examplehealth.com/job/12345",
  "salary": "$170k-$190k",
  "posted_at": "2025-10-26T03:00:00Z",
  "source": "indeed",
  "match_score": 85,
  "resume_summary": "Experienced DevOps engineer...",
  "resume_bullets": ["Led cloud migration...", "Implemented Kubernetes..."],
  "missing_keywords": ["Terraform", "Azure DevOps"],
  "cover_letter": "Dear Hiring Team...",
  "model_used": "anthropic/claude-3.5-sonnet",
  "email": "candidate@example.com",
  "resume_base_text": "John Doe\nSenior DevOps Engineer..."
}
```

### After Assemble Tailored Content
```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "location": "Los Angeles, CA (Hybrid)",
  "apply_url": "https://careers.examplehealth.com/job/12345",
  "salary": "$170k-$190k",
  "match_score": 85,
  "model_used": "anthropic/claude-3.5-sonnet",
  "email": "candidate@example.com",
  "tailored_resume_text": "PROFESSIONAL SUMMARY\nExperienced DevOps engineer...\n\nKEY ACHIEVEMENTS...",
  "cover_letter_text": "Dear Hiring Team at Example Health..."
}
```

## 10. Error Response Schemas

### Apify Error
```json
{
  "error": {
    "type": "run-failed",
    "message": "Actor run failed: insufficient credits"
  }
}
```

### OpenRouter Error
```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

### Google API Error
```json
{
  "error": {
    "code": 403,
    "message": "The caller does not have permission",
    "status": "PERMISSION_DENIED"
  }
}
```

## Schema Validation Notes

1. **All date-times** must be in ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`
2. **All URLs** must be valid HTTP/HTTPS URLs
3. **Email addresses** must match standard email format
4. **Match scores** must be integers between 0-100
5. **Source field** must be one of the 5 supported platforms
6. **AI responses** must be valid JSON conforming to AI Analysis Output Schema

## Schema Usage in n8n

### Validation Example (Function Node)
```javascript
// Validate canonical job object
function validateJob(job) {
  const required = ['job_title', 'company', 'description', 'source'];
  for (const field of required) {
    if (!job[field]) {
      throw new Error(`Missing required field: ${field}`);
    }
  }
  
  const validSources = ['indeed', 'linkedin', 'glassdoor', 'upwork', 'adzuna'];
  if (!validSources.includes(job.source)) {
    throw new Error(`Invalid source: ${job.source}`);
  }
  
  return true;
}
```

### Type Coercion Example
```javascript
// Ensure match_score is an integer
const match_score = parseInt(aiOutput.match_score, 10);
if (isNaN(match_score) || match_score < 0 || match_score > 100) {
  throw new Error('Invalid match_score');
}
```

---

**End of Schemas Document**

Use these schemas for validation, testing, and ensuring data consistency throughout the workflow.
