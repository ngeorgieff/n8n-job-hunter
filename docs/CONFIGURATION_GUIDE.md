# Configuration Guide - UI-Based Setup

## Overview

All configuration is now done directly in the n8n UI - **no external configuration files needed!**

This makes it easier to:
- ✅ Configure everything in one place
- ✅ See your settings at a glance
- ✅ No file system access required
- ✅ Works on n8n Cloud and self-hosted

## Quick Start Configuration

### Step 1: Open the Orchestrator Workflow

1. Open n8n UI (http://localhost:5678)
2. Go to **Workflows**
3. Open **Job Hunter - Main Orchestrator**

### Step 2: Configure Job Search Criteria

1. Click on the **"Set Configuration"** node (second node in the workflow)
2. You'll see all configurable settings in the UI:

#### Search Criteria

**Keywords** (what jobs to search for):
```
software engineer, developer, full stack, backend, frontend
```
- Edit this list to match your desired job titles
- Separate with commas
- Can include technologies (e.g., "python developer, react engineer")

**Locations** (where you want to work):
```
remote, San Francisco, New York, Austin
```
- Add your preferred locations
- Include "remote" for remote jobs
- Separate with commas

**Experience Levels**:
```
mid-level, senior
```
- Options: junior, mid-level, senior, lead, principal
- Separate with commas

**Salary Range**:
- **Min Salary**: `80000` (change to your minimum)
- **Max Salary**: `180000` (change to your maximum)
- Currency: USD (hardcoded, can modify in code)

**Job Types**:
```
full-time, contract
```
- Options: full-time, part-time, contract, temporary
- Separate with commas

**Exclude Keywords** (filter out unwanted jobs):
```
unpaid, commission only, internship
```
- Jobs containing these terms will be filtered out
- Separate with commas

#### Platform Settings

**Enable/Disable Job Boards**:
- **LinkedIn Enabled**: `true/false`
- **Indeed Enabled**: `true/false`
- **Remote Jobs Enabled**: `true/false`

Toggle these on/off to control which platforms to scrape.

### Step 3: Save Changes

1. Click **Save** in the top right
2. Your configuration is now active!

## Example Configurations

### Configuration 1: Senior Developer, Remote Only

```
Keywords: senior developer, senior engineer, tech lead
Locations: remote
Experience Levels: senior, lead
Min Salary: 120000
Max Salary: 200000
Job Types: full-time
Exclude Keywords: junior, entry level, unpaid, commission
```

### Configuration 2: Full Stack Developer, Major Cities

```
Keywords: full stack developer, full stack engineer
Locations: San Francisco, New York, Seattle, Austin, remote
Experience Levels: mid-level, senior
Min Salary: 90000
Max Salary: 160000
Job Types: full-time, contract
Exclude Keywords: internship, unpaid, part-time
```

### Configuration 3: Junior Developer, Learning Focus

```
Keywords: junior developer, entry level developer, software engineer
Locations: remote, any
Experience Levels: junior, entry level
Min Salary: 50000
Max Salary: 90000
Job Types: full-time
Exclude Keywords: unpaid, senior required, 5+ years
```

## Advanced Configuration

### Modifying the Schedule

1. Click on **"Schedule Trigger - Every 6 Hours"** node
2. Modify the interval:
   - **Hours**: Change `hoursInterval` from `6` to your preferred frequency
   - Or switch to cron expression for more control

**Common Schedules**:
- Every 3 hours: `hoursInterval: 3`
- Every 12 hours: `hoursInterval: 12`
- Daily at 9 AM: Use cron `0 9 * * *`

### Passing Configuration to Sub-Workflows

The configuration data is automatically passed to all sub-workflows through the Execute Workflow nodes. The data flows like this:

```
Set Configuration Node
  ↓
  $json.searchCriteria.keywords
  $json.searchCriteria.locations
  $json.searchCriteria.minSalary
  etc.
  ↓
Execute Workflow Nodes (receive this data)
  ↓
Sub-workflows can access via $input.all()
```

## Credentials Configuration

While job search criteria are in the UI, API credentials are still managed via n8n's credential system:

### Required Credentials

1. **LinkedIn OAuth2 API**
   - Go to Credentials → Add Credential → LinkedIn OAuth2 API
   - Enter Client ID and Client Secret
   - Save

2. **PostgreSQL** (for database)
   - Go to Credentials → Add Credential → Postgres
   - Enter host, port, database, username, password
   - Save

3. **SMTP** (for email notifications)
   - Go to Credentials → Add Credential → SMTP
   - Enter mail server details
   - Save

## Testing Your Configuration

### Manual Test Run

1. Open the orchestrator workflow
2. Click **"Execute Workflow"** button (top right)
3. Watch the execution in real-time
4. Check the output of each node

### Verify Configuration

1. After execution, click on **"Set Configuration"** node
2. Click **"View Output"** to see the configuration object
3. Verify all values are correct

## Troubleshooting

### Configuration Not Being Used

**Problem**: Changes to configuration don't seem to apply

**Solution**:
1. Make sure you clicked **Save** after editing
2. Re-execute the workflow (changes only apply on next run)
3. Check the "Set Configuration" node output to verify values

### Platform Not Scraping

**Problem**: LinkedIn/Indeed/Remote jobs not being scraped

**Solution**:
1. Check the platform is **Enabled** in "Set Configuration"
2. Verify the "LinkedIn Enabled?" switch node shows "enabled" path
3. Ensure the sub-workflow exists and is named correctly

### No Jobs Found

**Problem**: Workflow runs but finds no jobs

**Solution**:
1. **Broaden search criteria**:
   - Add more keywords
   - Add more locations
   - Lower minimum salary
2. **Check API credentials** are configured correctly
3. **Verify filters** aren't too restrictive (remove exclude keywords temporarily)
4. **Test each scraper individually** by executing sub-workflows directly

## Configuration Best Practices

### 1. Start Broad, Then Narrow

- Begin with many keywords and locations
- After first run, analyze results
- Add exclude keywords to filter out unwanted jobs

### 2. Use Multiple Keywords

Instead of:
```
software engineer
```

Use:
```
software engineer, software developer, backend engineer, full stack developer
```

### 3. Include Remote

Always include "remote" in locations unless you specifically don't want remote jobs:
```
remote, New York, San Francisco
```

### 4. Realistic Salary Ranges

Set min/max that match market rates for your level:
- Junior: $50k-$90k
- Mid: $80k-$140k
- Senior: $120k-$200k+

### 5. Test Incrementally

1. Start with 1 platform enabled
2. Verify it works
3. Enable additional platforms
4. Monitor results

## Migrating from File-Based Config

If you were using `config/settings.json` before:

### Old Way (File-Based):
```json
{
  "jobSearch": {
    "keywords": ["software engineer"],
    "locations": ["remote"]
  }
}
```

### New Way (UI-Based):
1. Open "Set Configuration" node
2. Edit **searchCriteria.keywords**: `software engineer`
3. Edit **searchCriteria.locations**: `remote`
4. Save

**Benefits**:
- ✅ No file system access needed
- ✅ Works on n8n Cloud
- ✅ Visual editing
- ✅ Immediate feedback

## Next Steps

1. ✅ Configure your job search criteria in the UI
2. ✅ Set up API credentials
3. ✅ Test manually with "Execute Workflow"
4. ✅ Activate the workflow for scheduled execution
5. ✅ Monitor results and refine configuration

## Support

If you have questions:
- Check the main [README.md](../README.md)
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for system design
- See [WORKFLOW_GUIDE.md](./WORKFLOW_GUIDE.md) for detailed workflow info

---

**Last Updated**: January 2025
**Version**: 2.0 (UI-based configuration)
