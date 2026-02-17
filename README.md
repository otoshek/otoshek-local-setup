# otoshek-local-setup

A Claude Code skill that sets up a complete local development environment for your Otoshek-deployed SaaS project.

## What it does

After Otoshek deploys your SaaS app, you'll receive a GitHub repository. This skill automates cloning and configuring everything you need to start building locally:

- Installs system dependencies (Homebrew, Git, mkcert, PostgreSQL, Python 3.13, Node.js, VS Code)
- Configures HTTPS SSL certificates for local development
- Creates and configures a local PostgreSQL database
- Sets up the Python virtual environment and installs dependencies
- Applies Django migrations and creates a superuser
- Configures environment variables (Google OAuth, Mailjet, Stripe)
- Syncs Stripe products and pricing from test mode
- Sets up VS Code with F5 launch for Django + React simultaneously

Supports **macOS**, **Linux**, and **Windows**. Auto-detects what is already installed and skips completed steps.

## Installation

```bash
claude mcp add https://github.com/otoshek/otoshek-local-setup
```

Or install via Claude Code settings → Plugins → Add from GitHub → `otoshek/otoshek-local-setup`.

## Usage

Open Claude Code in the directory where you want to clone your project, then run:

```
/otoshek-local-setup git@github.com:YOUR_USERNAME/YOUR_REPO.git
```

You can also provide an HTTPS URL — the skill will convert it automatically:

```
/otoshek-local-setup https://github.com/YOUR_USERNAME/YOUR_REPO
```

Claude will guide you through the full setup, pausing only when human action is required (e.g., adding an SSH key to GitHub, providing API credentials).

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed
- A GitHub account with access to your Otoshek repository
- Your API credentials ready (Google OAuth, Mailjet, Stripe — provided during your Otoshek onboarding)
