# Agent Instructions for n8n-job-hunter

This file provides custom instructions for GitHub Copilot coding agent and other AI assistants working on this repository.

## Project Overview

This repository contains n8n workflows and automation tools for job hunting. The project focuses on automating job search, application tracking, and related processes using n8n.

## General Guidelines

- **Code Quality**: Write clean, maintainable, and well-documented code
- **Testing**: Add tests for new features and bug fixes when applicable
- **Documentation**: Update README.md and relevant documentation when adding features or making significant changes
- **Version Control**: Make small, focused commits with clear commit messages
- **Dependencies**: Only add new dependencies when absolutely necessary; justify additions in PR descriptions

## Technology Stack

- **Platform**: Node.js/JavaScript/TypeScript
- **Primary Tool**: n8n (workflow automation)
- **Package Manager**: npm or yarn (check package.json for the primary one)

## Coding Standards

### JavaScript/TypeScript
- Use modern ES6+ syntax
- Prefer `const` and `let` over `var`
- Use arrow functions where appropriate
- Apply consistent naming conventions:
  - camelCase for variables and functions
  - PascalCase for classes and components
  - UPPER_CASE for constants
- Add JSDoc comments for public functions and complex logic

### n8n Workflows
- Use descriptive node names that explain their purpose
- Add notes to complex workflows explaining the logic
- Keep workflows modular and reusable where possible
- Document required credentials and environment variables

## Task Guidelines

### Bug Fixes
- Identify the root cause before making changes
- Add or update tests to prevent regression
- Document the fix in commit messages

### New Features
- Ensure features align with the project's job hunting automation purpose
- Consider backwards compatibility
- Update documentation and examples

### Documentation
- Use clear, concise language
- Include code examples where helpful
- Update table of contents if modifying structure
- Ensure examples are tested and working

### Refactoring
- Maintain existing functionality
- Run tests before and after changes
- Make incremental changes rather than large rewrites

## Build and Testing

- Run linters before committing (if configured)
- Ensure all tests pass before creating pull requests
- Test workflows in n8n before committing
- Validate JSON files are properly formatted

## Pull Request Guidelines

- Use descriptive PR titles that summarize the change
- Include context and motivation in PR descriptions
- Reference related issues using keywords (e.g., "Fixes #123")
- Request review from maintainers
- Address review feedback promptly

## Security Considerations

- Never commit sensitive information (API keys, credentials, passwords)
- Use environment variables for configuration
- Follow n8n security best practices for credential management
- Validate and sanitize user inputs in custom code

## Common Patterns

### Environment Variables
- Document required environment variables in README.md
- Use `.env.example` as a template
- Never commit actual `.env` files

### Error Handling
- Implement proper error handling in workflows
- Log meaningful error messages
- Provide graceful fallbacks where appropriate

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)

## Notes for AI Assistants

- This is a specialized project focused on job hunting automation
- Be cautious with changes that might affect existing workflows
- When in doubt about n8n-specific functionality, consult n8n documentation
- Prioritize solutions that are maintainable and easy for users to understand
