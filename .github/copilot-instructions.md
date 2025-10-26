# Copilot Instructions for n8n-job-search-automation

## Project Overview

This project automates multi-board job searches using n8n, integrating Apify, Adzuna, Google Sheets, Gmail, and OpenRouter AI. The workflow fetches job listings, deduplicates them, analyzes matches with AI, generates tailored resumes and cover letters, and emails results automatically.

## Key Conventions

### Directory Structure

- Source files and workflow templates go in `src/` (e.g., `src/workflows/`, `src/utils/`).
- Configurations and credentials examples in `config/`.
- GitHub-specific workflows and documentation in `.github/`.

### Documentation

- Main details in `README.md`.
- Update `.github/copilot-instructions.md` when adding new nodes, APIs, or architectural conventions.

## Development Workflows

### Setup

- Ensure all n8n, Apify, Google API, and OpenRouter dependencies are configured.
- Provide a `docker-compose.yml` for local n8n + Postgres environment.

### Testing

- Add workflow validation tests under `tests/` (e.g., mock API responses for Apify/Adzuna).
- Use consistent naming (`test_job_scraper.js`, `test_ai_integration.js`).

### Builds

- Document build or deploy steps in `README.md` or a `Makefile`.
- Example: `make build && make start` for local testing.

### Documentation

- `README.md` is auto-generated via GitHub Actions using LLM analysis on code changes.
- Local generation: `./scripts/generate-readme.sh` (requires `OPENAI_API_KEY`).
- Manual trigger via `workflow_dispatch`.

## Patterns and Practices

### Integration Points

- Keep API logic (Apify, Adzuna, OpenRouter) isolated in `src/integrations/`.
- Use environment variables for all credentials (`.env.example` provided).

### Extensibility

- Allow easy addition of new job sources or AI providers.
- New AI models can be added by extending the OpenRouter integration node.

### Examples

- Place demo workflows under `examples/` (e.g., `examples/jobhunt-basic.json`).
- Include node configuration references and test credentials examples.

## Next Steps

Update this file as the project evolves to include:

- Major workflow architecture decisions
- New integrations or modules
- Unique environment or credential setups

## Automated Documentation

- Set `OPENAI_API_KEY` secret in GitHub repo settings.
- The auto-README workflow triggers on pushes to main when source or config files change.
- Generated `README.md` will commit automatically or open a PR for feature branches.
