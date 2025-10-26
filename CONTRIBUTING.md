# Contributing to n8n Job Hunter

Thank you for your interest in contributing to the n8n Job Hunter project! This document provides guidelines and instructions for contributing.

## Ways to Contribute

There are many ways to contribute to this project:

- 🐛 **Report bugs** - Found an issue? Let us know!
- 💡 **Suggest features** - Have an idea? Share it!
- 📝 **Improve documentation** - Help others understand the project
- 🔧 **Fix bugs** - Submit a pull request
- ✨ **Add features** - Implement new functionality
- 🌍 **Add job platforms** - Integrate more job sources
- 🎨 **Improve workflow** - Optimize the n8n workflow

## Getting Started

1. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/n8n-job-hunter.git
   cd n8n-job-hunter
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

## Making Changes

### Workflow Changes

If you're modifying the n8n workflow:

1. **Make changes in n8n UI**
   - Import the workflow
   - Make your modifications
   - Test thoroughly

2. **Export the workflow**
   - Workflows → ... → Download
   - Save as `job-hunter-workflow.json`

3. **Clean sensitive data**
   ```bash
   # Remove any credentials or personal data
   # Ensure credential references use variables like $credentials
   ```

4. **Validate JSON**
   ```bash
   python3 -m json.tool job-hunter-workflow.json > /dev/null
   ```

### Documentation Changes

If you're updating documentation:

1. **Use clear language** - Write for beginners
2. **Add examples** - Show, don't just tell
3. **Test instructions** - Verify steps work
4. **Update table of contents** - If adding sections

### Code Changes

If you're adding code (e.g., validation scripts):

1. **Follow existing style**
2. **Add comments** for complex logic
3. **Test your code**
4. **Update documentation**

## Commit Guidelines

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add ZipRecruiter integration to workflow"
git commit -m "Fix deduplication logic for edge cases"
git commit -m "Update SETUP.md with troubleshooting steps"

# Not so good
git commit -m "Update stuff"
git commit -m "Fix bug"
```

### Commit Message Format

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Example:**
```
feat: Add ZipRecruiter job scraping node

- Add HTTP Request node for ZipRecruiter API
- Update merge logic to include ZipRecruiter
- Add configuration documentation

Closes #123
```

## Pull Request Process

1. **Update documentation**
   - Update README.md if needed
   - Update SETUP.md for new features
   - Update NODE_CONFIG.md for new nodes

2. **Test your changes**
   - Import workflow and test
   - Verify all nodes work
   - Check error handling

3. **Create pull request**
   - Go to GitHub
   - Click "New Pull Request"
   - Fill in the template

4. **Pull request template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Workflow optimization
   
   ## Testing
   - [ ] Tested locally
   - [ ] All nodes execute successfully
   - [ ] Documentation updated
   
   ## Screenshots (if applicable)
   Add screenshots of workflow changes
   ```

## Adding New Job Platforms

Want to add a new job source? Here's how:

### 1. Research the Platform

- Does it have an API? (preferred)
- Is there an Apify scraper?
- What's the rate limit?
- Is authentication required?

### 2. Add the Node

```json
{
  "parameters": {
    "method": "GET",
    "url": "https://api.newplatform.com/jobs",
    "queryParameters": {
      "parameters": [
        {"name": "query", "value": "={{$node['Set Job Parameters'].json['keyword']}}"},
        {"name": "location", "value": "={{$node['Set Job Parameters'].json['location']}}"}
      ]
    }
  },
  "name": "New Platform Jobs",
  "type": "n8n-nodes-base.httpRequest"
}
```

### 3. Add Processing Logic

If the response format is different:

```javascript
// In a Code node
const items = [];
for (const item of $input.all()) {
  // Parse response specific to this platform
  items.push({
    json: {
      title: item.job_title,
      company: item.employer,
      // ... map other fields
      source: 'NewPlatform'
    }
  });
}
return items;
```

### 4. Update Connections

Connect the new node to "Merge All Results"

### 5. Document It

Update:
- README.md (add to features list)
- SETUP.md (add credential setup if needed)
- NODE_CONFIG.md (add node configuration)

## Testing Guidelines

### Manual Testing Checklist

Before submitting:

- [ ] Workflow imports without errors
- [ ] All credentials can be configured
- [ ] Schedule trigger works
- [ ] Each job source returns results
- [ ] Deduplication removes duplicates
- [ ] Google Sheets updates correctly
- [ ] AI processing works
- [ ] Email sends successfully
- [ ] Documentation is accurate
- [ ] No sensitive data in workflow JSON

### Testing New Features

1. **Test in isolation** - Test new nodes separately
2. **Test integration** - Test with full workflow
3. **Test edge cases** - Empty results, API errors, etc.
4. **Test documentation** - Follow your own instructions

## Code of Conduct

### Our Standards

- **Be respectful** - Treat everyone with respect
- **Be constructive** - Provide helpful feedback
- **Be inclusive** - Welcome all contributors
- **Be patient** - Everyone is learning

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing private information
- Spamming or advertising

## Questions?

- **General questions**: Open a GitHub Discussion
- **Bug reports**: Open a GitHub Issue
- **Feature requests**: Open a GitHub Issue
- **Security issues**: Email directly (don't create public issue)

## Recognition

Contributors will be:
- Listed in the README.md
- Mentioned in release notes
- Credited in pull request merges

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Node Development](https://docs.n8n.io/integrations/creating-nodes/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

Thank you for contributing to n8n Job Hunter! 🙏
