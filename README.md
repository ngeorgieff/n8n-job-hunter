# n8n Job Hunter

An automated job hunting workflow built with n8n to streamline your job search process. This project helps you automatically search, track, and manage job applications across multiple platforms.

## Features

- 🔍 **Automated Job Search**: Scan multiple job boards and platforms automatically
- 📧 **Application Tracking**: Keep track of all your job applications in one place
- 🔔 **Smart Notifications**: Get notified about new job postings matching your criteria
- 📊 **Analytics Dashboard**: Track your application success rate and progress
- 🤖 **Auto-Apply**: Streamline the application process for supported platforms
- 💾 **Data Storage**: Store job listings and application history in a database

## Prerequisites

Before you begin, ensure you have the following installed:

- [n8n](https://n8n.io/) (version 0.200.0 or higher)
- Node.js (version 16.x or higher)
- npm or yarn package manager
- A database (PostgreSQL, MySQL, or SQLite)

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/ngeorgieff/n8n-job-hunter.git
   cd n8n-job-hunter
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up your environment variables:
   ```bash
   cp .env.example .env
   ```

4. Configure your `.env` file with your credentials:
   ```env
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=your_username
   N8N_BASIC_AUTH_PASSWORD=your_password

   # Database configuration
   DB_TYPE=postgresdb
   DB_HOST=localhost
   DB_PORT=5432
   DB_DATABASE=n8n_job_hunter
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password

   # Job board API keys (configure as needed)
   LINKEDIN_API_KEY=your_linkedin_key
   INDEED_API_KEY=your_indeed_key
   GLASSDOOR_API_KEY=your_glassdoor_key
   ```

## Configuration

### Job Search Criteria

Customize your job search parameters in the workflow settings:

- **Keywords**: Technologies, roles, or skills you're interested in
- **Location**: Preferred job locations or remote work options
- **Experience Level**: Junior, Mid-level, Senior, etc.
- **Salary Range**: Minimum and maximum salary expectations
- **Job Type**: Full-time, Part-time, Contract, etc.

### Supported Platforms

- LinkedIn
- Indeed
- Glassdoor
- Remote.co
- We Work Remotely
- Custom RSS feeds

## Usage

1. Start n8n:
   ```bash
   npm start
   ```

2. Access the n8n interface at `http://localhost:5678`

3. Import the job hunter workflows from the `workflows/` directory

4. Activate the workflows you want to use

5. Configure the workflow nodes with your specific requirements

## Workflows

### Main Workflows

- **Job Scraper**: Automatically searches for new job postings
- **Application Tracker**: Manages your application status
- **Notification Service**: Sends alerts for new matches
- **Analytics Generator**: Creates reports on your job search progress

## Project Structure

```
n8n-job-hunter/
├── workflows/           # n8n workflow JSON files
├── scripts/            # Utility scripts
├── config/             # Configuration files
├── docs/               # Additional documentation
└── README.md           # This file
```

## Customization

### Adding New Job Boards

1. Create a new workflow in n8n
2. Add HTTP Request nodes for the job board API
3. Configure data transformation nodes
4. Connect to the main job storage database

### Modifying Filters

Edit the workflow nodes to adjust:
- Search keywords
- Location filters
- Salary ranges
- Company preferences

## Troubleshooting

### Common Issues

**n8n won't start**
- Ensure all dependencies are installed
- Check that your database is running
- Verify your `.env` configuration

**No jobs appearing**
- Check your search criteria aren't too restrictive
- Verify API credentials are correct
- Check the workflow execution logs

**Database connection errors**
- Confirm database credentials in `.env`
- Ensure database service is running
- Check network connectivity

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Best Practices

- 🔒 Keep your API keys and credentials secure
- 📅 Set reasonable polling intervals to avoid rate limiting
- 🧹 Regularly clean up old job listings from the database
- 📝 Document any custom workflows you create
- 🔄 Keep n8n and dependencies updated

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is for personal use only. Always respect the terms of service of job boards and platforms you interact with. Be mindful of rate limits and avoid aggressive scraping that could violate platform policies.

## Support

- 📖 [n8n Documentation](https://docs.n8n.io/)
- 💬 [n8n Community Forum](https://community.n8n.io/)
- 🐛 [Report Issues](https://github.com/ngeorgieff/n8n-job-hunter/issues)

## Roadmap

- [ ] Add support for more job platforms
- [ ] Implement AI-powered job matching
- [ ] Create mobile notifications
- [ ] Add resume customization features
- [ ] Build interview scheduler integration
- [ ] Add salary comparison tools

## Acknowledgments

- Built with [n8n](https://n8n.io/)
- Inspired by the job hunting community
- Thanks to all contributors

---

**Happy Job Hunting! 🎯**
