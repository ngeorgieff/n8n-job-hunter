#!/bin/bash

set -e

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    echo "Please set it with: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

echo "Analyzing project structure and code..."

# Create a temporary file with project analysis
PROJECT_ANALYSIS=$(cat <<EOF
Analyze the following n8n Job Search Automation project and generate a comprehensive README.md.

Project Structure:
$(find src config examples -type f 2>/dev/null || echo "No files yet")

Key Files:
- docker-compose.yml: Local development environment
- .env.example: Configuration template
- Makefile: Build and deployment commands

Integration Points:
- Apify: Web scraping for job listings
- Adzuna: Job search API
- Google Sheets: Data storage and management
- Gmail: Email automation
- OpenRouter AI: AI-powered resume and cover letter generation

The project automates job searches across multiple boards, deduplicates results, 
analyzes matches with AI, and generates tailored application materials.

Generate a comprehensive README.md with:
1. Project title and description
2. Features
3. Prerequisites
4. Installation and setup instructions
5. Usage guide
6. Configuration details
7. Development workflow
8. Testing
9. Contributing guidelines
10. License information
EOF
)

echo "Generating README.md with OpenAI..."

# Call OpenAI API to generate README
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
    \"model\": \"gpt-4\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are a technical documentation expert. Generate clear, comprehensive README files for software projects.\"
      },
      {
        \"role\": \"user\",
        \"content\": $(echo "$PROJECT_ANALYSIS" | jq -Rs .)
      }
    ],
    \"temperature\": 0.7,
    \"max_tokens\": 2000
  }")

# Extract the generated content
GENERATED_README=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$GENERATED_README" ]; then
    echo "Error: Failed to generate README. API Response:"
    echo "$RESPONSE"
    exit 1
fi

# Write the generated README
echo "$GENERATED_README" > README.md

echo "✓ README.md generated successfully!"
