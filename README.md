# n8n Job Hunter

An automated job hunting workflow built with n8n using modern, modular architecture. This project helps you automatically search, track, and manage job applications across multiple platforms with intelligent filtering, deduplication, and multi-channel notifications.

## ✨ Key Features

- 🔍 **Multi-Platform Job Scraping**: Automated search across LinkedIn, Indeed, and remote job boards
- 🧠 **Intelligent Processing**: AI-powered skill detection, relevance scoring, and job enrichment
- 🔄 **Smart Deduplication**: Multiple strategies to eliminate duplicate listings
- 📊 **Advanced Analytics**: Track your job search progress with detailed metrics
- 🔔 **Multi-Channel Notifications**: Email, Slack, and Discord alerts for new opportunities
- 💾 **Robust Data Storage**: PostgreSQL database with full-text search and optimized indexes
- 🛡️ **Error Handling**: Comprehensive retry logic and rate limiting protection
- 📦 **Modular Architecture**: Following n8n 2025 best practices for maintainability

## 🏗️ Architecture

This project implements a **modular workflow architecture** based on n8n best practices:

```
Orchestrator
     ↓
Parallel Scrapers (LinkedIn, Indeed, Remote)
     ↓
Data Processing (Merge → Deduplicate → Enrich)
     ↓
Storage & Notifications
```

### Benefits of Modular Design

- ✅ **Reusable Components**: Sub-workflows can be used independently
- ✅ **Easy Maintenance**: Update one module without affecting others
- ✅ **Independent Testing**: Test each component in isolation
- ✅ **Scalability**: Add new scrapers or processors easily
- ✅ **Clear Separation**: Each workflow has a single responsibility

## 📋 Prerequisites

- [n8n](https://n8n.io/) version 0.200.0 or higher
- Node.js version 16.x or higher
- PostgreSQL 12+ (recommended) or MySQL/SQLite
- npm or yarn package manager

## 🚀 Quick Start

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/ngeorgieff/n8n-job-hunter.git
cd n8n-job-hunter

# Run the setup script
./scripts/setup.sh

# Set up the database
./scripts/setup-database.sh

# Import workflows
./scripts/import-workflows.sh
```

### 2. Configuration

1. **Edit `.env` file** with your credentials:
   ```bash
   cp .env.example .env
   nano .env
   ```

2. **Configure job search criteria** in `config/settings.json`:
   ```json
   {
     "jobSearch": {
       "keywords": ["software engineer", "developer"],
       "locations": ["remote", "San Francisco"],
       "salaryRange": { "min": 80000, "max": 180000 }
     }
   }
   ```

3. **Set up API credentials** in `config/credentials.json`:
   ```bash
   cp config/credentials.example.json config/credentials.json
   nano config/credentials.json
   ```

### 3. Start n8n and Import Workflows

```bash
# Start n8n
n8n start

# Open browser at http://localhost:5678
# Import workflows from the n8n UI:
# 1. Go to Workflows → Import from File
# 2. Import each .json file from workflows/ directories
# 3. Configure credentials in n8n UI
# 4. Activate the main orchestrator workflow
```

## 📁 Project Structure

```
n8n-job-hunter/
├── workflows/
│   ├── core/                       # Main orchestration workflows
│   │   └── job-hunter-orchestrator.json
│   ├── sub-workflows/              # Reusable sub-workflows
│   │   ├── linkedin-scraper.json   # LinkedIn job scraper
│   │   ├── deduplication.json      # Duplicate removal
│   │   ├── job-enrichment.json     # AI-powered enrichment
│   │   ├── database-storage.json   # Database operations
│   │   └── notifications.json      # Multi-channel alerts
│   └── jobs/                       # Job-specific workflows
├── config/
│   ├── settings.json               # Job search configuration
│   └── credentials.example.json    # API credentials template
├── scripts/
│   ├── setup.sh                    # Initial setup script
│   ├── setup-database.sh           # Database initialization
│   ├── import-workflows.sh         # Import workflows to n8n
│   └── export-workflows.sh         # Export workflows from n8n
├── docs/
│   ├── ARCHITECTURE.md             # Architecture documentation
│   └── WORKFLOW_GUIDE.md           # Workflow usage guide
├── .env.example                    # Environment variables template
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

## 🔧 Workflow Components

### Core Orchestrator
**File**: `workflows/core/job-hunter-orchestrator.json`

The main workflow that coordinates all sub-workflows:
- Runs on schedule (every 6 hours by default)
- Executes all scrapers in parallel
- Processes and stores results
- Sends notifications
- Handles errors

### LinkedIn Scraper
**File**: `workflows/sub-workflows/linkedin-scraper.json`

Features:
- OAuth2 authentication
- Keyword and location filtering
- Rate limiting protection
- Error handling with retries
- Data transformation to standard format

### Deduplication Processor
**File**: `workflows/sub-workflows/deduplication.json`

Removes duplicates using:
- Exact ID matching (source + job ID)
- URL matching
- Fuzzy matching (title + company + location)
- Keeps newest/richest data

### Job Enrichment
**File**: `workflows/sub-workflows/job-enrichment.json`

Adds intelligence:
- **Skill Detection**: Extracts 50+ technologies
- **Remote Analysis**: Identifies remote-friendly jobs
- **Experience Estimation**: Determines seniority level
- **Relevance Scoring**: Rates job match quality (0-100)

### Database Storage
**File**: `workflows/sub-workflows/database-storage.json`

Features:
- Auto-creates schema on first run
- Upserts (insert/update) job listings
- Prevents duplicates via composite key
- Optimized indexes for search
- Full-text search support

### Notifications
**File**: `workflows/sub-workflows/notifications.json`

Multi-channel alerts:
- **Email**: Beautiful HTML formatted emails
- **Slack**: Rich message blocks with apply buttons
- **Discord**: Webhook notifications
- Only sends when new jobs found

## ⚙️ Configuration

### Job Search Criteria (`config/settings.json`)

```json
{
  "jobSearch": {
    "keywords": ["software engineer", "full stack"],
    "locations": ["remote", "San Francisco"],
    "experienceLevels": ["mid-level", "senior"],
    "salaryRange": { "min": 80000, "max": 180000 },
    "jobTypes": ["full-time", "contract"],
    "excludeKeywords": ["unpaid", "internship"]
  },
  "platforms": {
    "linkedin": { "enabled": true },
    "indeed": { "enabled": true }
  },
  "notifications": {
    "email": { "enabled": true },
    "slack": { "enabled": false }
  }
}
```

### Schedule Configuration

Edit the Schedule Trigger node in the orchestrator:

```javascript
// Every 6 hours (default)
"0 */6 * * *"

// Every 3 hours
"0 */3 * * *"

// Daily at 9 AM
"0 9 * * *"

// Monday & Thursday at 9 AM
"0 9 * * MON,THU"
```

## 🎯 Usage

### Activate Workflows

1. Open n8n UI (http://localhost:5678)
2. Navigate to **Workflows**
3. Open **Job Hunter - Main Orchestrator**
4. Click **Active** toggle

⚠️ **Important**: Only activate the orchestrator. Sub-workflows should remain inactive.

### Manual Execution

Test workflows manually:
1. Open any workflow
2. Click **Execute Workflow** button
3. Review execution log
4. Check output data

### Monitor Executions

- View execution history in n8n UI
- Check logs for errors
- Monitor API rate limits
- Review database entries

## 🔍 Customization

### Add New Job Platform

1. Create scraper sub-workflow
2. Transform data to standard format:
   ```javascript
   {
     id: string,
     source: string,
     title: string,
     company: string,
     location: string,
     description: string,
     salary: { min: number, max: number },
     url: string,
     postedDate: string,
     jobType: string,
     experienceLevel: string
   }
   ```
3. Add to orchestrator workflow
4. Update configuration

### Customize Enrichment Logic

Edit `workflows/sub-workflows/job-enrichment.json`:

```javascript
// Add custom skill categories
const skillPatterns = {
  languages: ['javascript', 'python', ...],
  myCategory: ['custom', 'skills', ...]
};

// Modify relevance scoring
const score = skillCount * 5 + customFactor;
```

### Modify Filters

Add IF nodes with conditions:

```javascript
// Filter by keyword
{{ $json.title.toLowerCase().includes('senior') }}

// Filter by salary
{{ $json.salary?.min >= 100000 }}

// Exclude companies
{{ !['company1'].includes($json.company.toLowerCase()) }}
```

## 🗄️ Database Schema

### Jobs Table
Stores all job listings with:
- Composite primary key (source, id)
- Full-text search indexes
- JSONB metadata column
- Automatic timestamps

### Applications Table
Tracks your applications:
- Status tracking
- Notes and resume versions
- Foreign key to jobs table

### Additional Tables
- `saved_searches` - Search configurations
- `job_alerts` - Notification history

## 🛠️ Utility Scripts

### Setup Script
```bash
./scripts/setup.sh
```
Initializes environment, creates directories, and configures settings.

### Database Setup
```bash
./scripts/setup-database.sh
```
Creates PostgreSQL database, tables, and indexes.

### Import Workflows
```bash
./scripts/import-workflows.sh
```
Copies workflow files to n8n directory.

### Export Workflows
```bash
./scripts/export-workflows.sh
```
Backs up workflows from n8n to local directory.

## 📊 Monitoring & Analytics

### Execution Metrics
- Total jobs scraped
- Deduplication rate
- Enrichment coverage
- Notification delivery

### Database Queries

```sql
-- Recently scraped jobs
SELECT * FROM jobs
ORDER BY scraped_at DESC
LIMIT 20;

-- Jobs by company
SELECT company, COUNT(*)
FROM jobs
GROUP BY company
ORDER BY COUNT(*) DESC;

-- High relevance jobs
SELECT * FROM jobs
WHERE (metadata->>'enrichment->relevanceScore')::int > 70;
```

## 🐛 Troubleshooting

### Workflows Not Running

**Check**:
- Is orchestrator activated?
- Are credentials configured?
- Check execution logs

**Fix**:
```bash
# Test manually
# Open workflow → Execute Workflow

# Check n8n logs
n8n logs
```

### No Jobs Found

**Check**:
- Search criteria too restrictive?
- API credentials valid?
- Rate limiting?

**Fix**:
- Broaden keywords in `config/settings.json`
- Verify API keys
- Check rate limit delays

### Database Errors

**Check**:
```bash
# PostgreSQL running?
sudo systemctl status postgresql

# Connection valid?
psql -h localhost -U n8n_user -d n8n_job_hunter
```

**Fix**:
```bash
# Re-run database setup
./scripts/setup-database.sh
```

## 📚 Documentation

- [Architecture Documentation](docs/ARCHITECTURE.md) - System design and data flow
- [Workflow Guide](docs/WORKFLOW_GUIDE.md) - Detailed workflow usage
- [n8n Best Practices](https://docs.n8n.io/workflows/best-practices/)

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow n8n best practices
4. Test thoroughly
5. Submit a pull request

## 📝 Best Practices

- 🔒 **Security**: Never commit credentials, use environment variables
- ⏱️ **Rate Limiting**: Respect API limits, use delays
- 🧹 **Cleanup**: Regularly remove old job listings
- 📖 **Documentation**: Document custom workflows
- 🔄 **Updates**: Keep n8n and dependencies current
- 🧪 **Testing**: Test sub-workflows independently
- 📊 **Monitoring**: Check execution logs regularly

## 🚧 Roadmap

- [ ] Additional job platforms (Remote.co, We Work Remotely)
- [ ] Machine learning-based job matching
- [ ] Auto-apply functionality
- [ ] Interview tracking system
- [ ] Salary trend analysis
- [ ] Resume customization
- [ ] Cover letter generation
- [ ] Mobile app integration
- [ ] Chrome extension for quick saves

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool is for personal use only. Always respect the terms of service of job boards and platforms. Be mindful of rate limits and avoid aggressive scraping that could violate platform policies.

## 💡 Support

- 📖 [n8n Documentation](https://docs.n8n.io/)
- 💬 [n8n Community Forum](https://community.n8n.io/)
- 🐛 [Report Issues](https://github.com/ngeorgieff/n8n-job-hunter/issues)
- 📧 Questions? Open an issue or discussion

## 🙏 Acknowledgments

- Built with [n8n](https://n8n.io/) - workflow automation platform
- Inspired by the job hunting community
- Follows n8n 2025 best practices for modular design
- Thanks to all contributors and testers

---

**Made with ❤️ by the community | Happy Job Hunting! 🎯**

*Last updated: January 2025*
