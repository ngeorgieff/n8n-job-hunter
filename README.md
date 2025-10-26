# Job Hunt Auto-Pilot - n8n Workflow

An intelligent, automated job search and application system built for n8n that searches multiple job platforms, uses AI to tailor resumes and cover letters, and delivers personalized results to your inbox.

## 🎯 Overview

**Job Hunt Auto-Pilot** is a production-ready n8n workflow that:

- 🔍 **Searches 5 major job platforms**: LinkedIn, Indeed, Glassdoor, Upwork, and Adzuna
- 🤖 **Uses AI to analyze job fit**: Runs 3 LLM models in parallel to generate tailored content
- ✍️ **Creates custom resumes & cover letters**: For each relevant job based on your actual experience
- 📊 **Tracks everything in Google Sheets**: Complete audit trail of all jobs and AI analysis
- 📧 **Sends smart email alerts**: Only for high-scoring matches with tailored content
- 🔄 **Runs automatically**: Via webhook or scheduled cron jobs

## 🚀 Quick Start

1. **[Read the Quick Start Guide](QUICK_START_GUIDE.md)** - Get up and running in 30 minutes
2. **[Review the Workflow Documentation](WORKFLOW_DOCUMENTATION.md)** - Complete technical specification
3. **[Check API Configuration](API_CONFIGURATION.md)** - Set up all external services
4. **[Understand Data Schemas](DATA_SCHEMAS.md)** - Data models and validation

## 📋 Documentation

### Core Documents
- **[WORKFLOW_DOCUMENTATION.md](WORKFLOW_DOCUMENTATION.md)** - Complete workflow specification with all 24 nodes, function code, and AI prompts
- **[QUICK_START_GUIDE.md](QUICK_START_GUIDE.md)** - Step-by-step setup instructions
- **[DATA_SCHEMAS.md](DATA_SCHEMAS.md)** - JSON schemas for all data structures
- **[API_CONFIGURATION.md](API_CONFIGURATION.md)** - API endpoints, authentication, and rate limits

## 🏗️ Architecture

### Workflow Flow
```
Webhook/Cron → Extract Resume → Scrape Jobs (5 sources) → Normalize → Dedupe → 
Filter → Save to Sheets → AI Analysis (3 models) → Rank Best → Assemble Content → 
Update Sheets → Email High Matches
```

### Technology Stack
- **Workflow Engine**: n8n (self-hosted)
- **Job Sources**: Apify (LinkedIn, Indeed, Glassdoor, Upwork) + Adzuna API
- **AI Models**: Claude 3.5 Sonnet, GPT-4o Mini, Gemini 1.5 Pro (via OpenRouter)
- **Storage**: Google Sheets
- **Notifications**: Gmail
- **Resume Parsing**: Binary to text extraction

## 💡 Key Features

### Multi-Source Job Aggregation
Searches 5 platforms simultaneously and normalizes all results into a consistent format:
- **LinkedIn** - Professional network jobs
- **Indeed** - General job board
- **Glassdoor** - Company reviews + jobs
- **Upwork** - Freelance opportunities
- **Adzuna** - Aggregated listings

### AI-Powered Analysis
For each relevant job, the workflow:
1. Sends job description + your resume to 3 AI models
2. Gets match score (0-100), tailored resume bullets, and custom cover letter
3. Ranks outputs and selects the best based on match score and quality
4. Saves everything to Google Sheets for review

### Smart Filtering & Deduplication
- Removes duplicate jobs by title + company
- Filters for relevant keywords (DevOps, Cloud, Platform, etc.)
- Only emails jobs with match score ≥ 70%

## 📊 Data Models

### Canonical Job Object
```json
{
  "job_title": "Senior Cloud DevOps Engineer",
  "company": "Example Health",
  "location": "Los Angeles, CA (Hybrid)",
  "description": "Clean plain-text description...",
  "apply_url": "https://careers.example.com/job/12345",
  "salary": "$170k-$190k",
  "posted_at": "2025-10-26T03:00:00Z",
  "source": "indeed"
}
```

### AI Analysis Output
```json
{
  "match_score": 85,
  "resume_summary": "Tailored professional summary...",
  "resume_bullets": ["Bullet 1...", "Bullet 2..."],
  "missing_keywords": ["Terraform", "Azure"],
  "cover_letter": "Dear Hiring Team...",
  "model_used": "anthropic/claude-3.5-sonnet"
}
```

## 🔧 Prerequisites

### Required Accounts & Credentials
1. **Apify Account** - For job scraping ($49/month Personal plan recommended)
2. **Adzuna API** - Free tier (5,000 calls/month)
3. **OpenRouter Account** - Pay-per-token AI access
4. **Google Cloud** - OAuth2 for Sheets + Gmail (free)
5. **n8n Instance** - Self-hosted (v1.0+)

### Estimated Monthly Costs
- **Light usage** (weekly runs): ~$10/month
- **Daily runs**: ~$70/month
- **On-demand only**: Variable (~$2.30 per run)

See [API_CONFIGURATION.md](API_CONFIGURATION.md) for detailed cost breakdown.

## 🎓 How It Works

### 1. Trigger
Send a POST request to the webhook:
```json
{
  "jobSearchKeyword": "Senior DevOps Engineer",
  "email": "your-email@example.com"
}
```
Include your resume as a binary file upload.

### 2. Job Search
Workflow queries all 5 platforms in parallel, collecting up to 250 jobs total (50 per source).

### 3. Normalization
All jobs are mapped to a consistent schema, HTML is stripped, and duplicates are removed.

### 4. AI Analysis
For each relevant job:
- 3 AI models analyze the fit
- Generate tailored resume content
- Create custom cover letter
- Best output is selected

### 5. Results
- All jobs saved to Google Sheets with status tracking
- Emails sent for high-scoring matches (≥70%)
- Complete audit trail maintained

## 📦 What's Included

### Function Nodes (Ready to Copy-Paste)
- `Extract Resume Text` - Convert PDF/DOCX to plain text
- `Normalize Jobs` - Map all sources to canonical schema
- `Dedupe Jobs` - Remove duplicates
- `Prepare AI Payload` - Build prompts for LLMs
- `Rank AI Outputs` - Select best AI response
- `Assemble Tailored Content` - Combine resume + cover letter

### AI Prompt Template
Production-ready prompt that instructs AI models to:
- Score job match (0-100)
- Generate tailored resume summary
- Create relevant bullet points
- Identify missing keywords
- Write custom cover letter

All without hallucinating qualifications!

### Email Templates
HTML and plain text templates for professional job match notifications.

## 🔒 Security & Privacy

- **No hardcoded secrets** - All credentials stored in n8n
- **Resume privacy** - Consider data privacy when using external AI APIs
- **OAuth scopes** - Minimum required permissions for Google services
- **API key rotation** - Recommended every 90 days
- **Audit logging** - Track all API calls and changes

## 🛠️ Customization

### Easy Customizations
- **Job sources**: Add/remove platforms in merge nodes
- **AI models**: Swap models in OpenRouter nodes
- **Filter keywords**: Update relevance filter logic
- **Match threshold**: Change from 70% to your preference
- **Email frequency**: Adjust cron schedule

### Advanced Customizations
- **Resume parsing**: Add proper PDF/DOCX libraries
- **Multi-language**: Translate prompts and templates
- **Application tracking**: Extend Google Sheets schema
- **Auto-apply**: Add application submission nodes
- **Slack/Discord**: Replace Gmail with other notifications

## 📈 Workflow Metrics

The workflow includes:
- **24 nodes total**
- **5 data sources**
- **3 AI models**
- **8 Function nodes**
- **4 conditional branches**
- **2 trigger types** (webhook + cron)

Average execution time: 2-5 minutes per run (depending on number of jobs)

## 🤝 Contributing

This is a documentation project providing a complete workflow specification. To contribute:

1. Fork the repository
2. Add improvements to documentation
3. Submit pull request with clear description
4. Focus on clarity and completeness

Potential contributions:
- Additional job sources
- Alternative AI prompts
- Optimization strategies
- Error handling improvements
- Multi-language support

## 📝 License

This project is provided as-is for educational and commercial use. No warranty provided.

## 🙏 Acknowledgments

Built for the n8n community by job seekers, for job seekers.

### Technologies Used
- [n8n](https://n8n.io) - Workflow automation platform
- [Apify](https://apify.com) - Web scraping platform
- [Adzuna API](https://developer.adzuna.com) - Job search API
- [OpenRouter](https://openrouter.ai) - Unified LLM API
- [Google Workspace APIs](https://developers.google.com) - Sheets & Gmail

## 🆘 Support

For issues or questions:
1. Check [QUICK_START_GUIDE.md](QUICK_START_GUIDE.md) troubleshooting section
2. Review [API_CONFIGURATION.md](API_CONFIGURATION.md) for API issues
3. Open an issue in this repository
4. Ask in n8n community forums

## 🗺️ Roadmap

Potential v2 features:
- [ ] More job platforms (Monster, ZipRecruiter, etc.)
- [ ] Persistent deduplication (Redis/database)
- [ ] User preference dashboard
- [ ] Automatic application submission
- [ ] Application status tracking
- [ ] Interview scheduler integration
- [ ] Salary negotiation insights
- [ ] A/B testing for resume variations

---

**Ready to automate your job hunt?** Start with the [Quick Start Guide](QUICK_START_GUIDE.md)!

## 📸 Preview

The workflow processes jobs like this:
1. **Search** → 250 jobs from 5 sources
2. **Normalize** → Consistent schema
3. **Dedupe** → ~150 unique jobs
4. **Filter** → ~50 relevant jobs
5. **AI Analysis** → ~30 high-quality matches
6. **Email** → Top 10-15 jobs (≥70% match)

All jobs tracked in Google Sheets for manual review and follow-up.