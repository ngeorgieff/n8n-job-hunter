# n8n Job Search Automation

An automated job search workflow built with n8n that integrates multiple job boards, AI-powered matching, and automated application material generation.

## Features

- 🔍 **Multi-Source Job Scraping**: Integrates with Apify and Adzuna to fetch job listings from multiple sources
- 🔄 **Intelligent Deduplication**: Automatically removes duplicate job postings across different platforms
- 🤖 **AI-Powered Matching**: Uses OpenRouter AI to analyze job matches based on your profile
- 📝 **Automated Resume Generation**: Creates tailored resumes for each job application
- ✉️ **Email Automation**: Sends application materials via Gmail automatically
- 📊 **Data Management**: Stores and tracks applications in Google Sheets

## Prerequisites

- Docker and Docker Compose
- API keys for:
  - Apify
  - Adzuna
  - OpenRouter
  - Google Cloud (for Sheets and Gmail)
  - OpenAI (for README generation)

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ngeorgieff/n8n-job-hunter.git
   cd n8n-job-hunter
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and credentials
   ```

3. **Start the services**:
   ```bash
   make build
   make start
   ```

4. **Access n8n**:
   - Open http://localhost:5678 in your browser
   - Default credentials: admin/admin (change in .env)

## Configuration

### API Credentials

Configure your API credentials in the `.env` file:

```env
APIFY_API_KEY=your_apify_key
ADZUNA_APP_ID=your_adzuna_app_id
ADZUNA_API_KEY=your_adzuna_key
GOOGLE_SHEETS_CLIENT_EMAIL=your_service_account_email
GOOGLE_SHEETS_PRIVATE_KEY=your_private_key
GMAIL_CLIENT_ID=your_gmail_client_id
GMAIL_CLIENT_SECRET=your_gmail_client_secret
OPENROUTER_API_KEY=your_openrouter_key
```

### Workflow Configuration

Customize the workflow behavior in `config/workflow-config.example.json`:

- Search keywords and locations
- Salary requirements
- AI model preferences
- Email settings

## Usage

### Using Docker Compose

```bash
# Start services
make start

# View logs
make logs

# Stop services
make stop

# Restart services
make restart

# Clean up (removes containers and volumes)
make clean
```

### Importing Workflows

1. Navigate to http://localhost:5678
2. Go to Workflows → Import
3. Select one of the example workflows from `examples/`
4. Configure credentials for each node
5. Activate the workflow

### Running Tests

```bash
make test
```

## Development

### Project Structure

```
.
├── .github/
│   ├── copilot-instructions.md    # Development guidelines
│   └── workflows/                 # GitHub Actions workflows
├── config/                        # Configuration examples
├── examples/                      # Example n8n workflows
├── scripts/                       # Utility scripts
├── src/
│   ├── integrations/             # API integration modules
│   ├── utils/                    # Utility functions
│   └── workflows/                # Workflow templates
└── tests/                        # Test files
```

### Adding New Integrations

1. Create a new integration module in `src/integrations/`
2. Follow the existing pattern (see `openrouter.js` for reference)
3. Add tests in `tests/`
4. Update `.env.example` with required credentials
5. Update this README

### Adding New AI Models

New AI models can be added by extending the OpenRouter integration:

```javascript
const openrouter = require('./src/integrations/openrouter');
openrouter.addModel('custom-model', {
  temperature: 0.7,
  maxTokens: 2000
});
```

## Automated Documentation

This README can be automatically regenerated based on code changes:

### Setup

1. Add `OPENAI_API_KEY` to GitHub repository secrets
2. The workflow triggers automatically on pushes to `main` when files in `src/`, `config/`, or `examples/` change

### Manual Generation

```bash
export OPENAI_API_KEY=your_key
./scripts/generate-readme.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [n8n documentation](https://docs.n8n.io)
- Review the examples in the `examples/` directory

## Acknowledgments

- Built with [n8n](https://n8n.io)
- Powered by [OpenRouter](https://openrouter.ai)
- Job data from [Apify](https://apify.com) and [Adzuna](https://www.adzuna.com)