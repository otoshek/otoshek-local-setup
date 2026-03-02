# otoshek-local-setup

A Claude Code skill that sets up a complete local development environment for your Otoshek-deployed SaaS project.

## What it does

After Otoshek deploys your SaaS app, you'll receive a GitHub repository. This skill automates cloning and configuring everything you need to start building locally:

- Verifies system prerequisites are installed (see below) and stops with install commands if any are missing
- Installs and configures PostgreSQL and VS Code
- Configures HTTPS SSL certificates for local development
- Creates and configures a local PostgreSQL database
- Sets up the Python virtual environment and installs dependencies
- Applies Django migrations and creates a superuser
- Configures environment variables (Google OAuth, Mailjet, Stripe)
- Syncs Stripe products and pricing from test mode
- Sets up VS Code with F5 launch for Django + React simultaneously

Supports **macOS**, **Linux**, and **Windows**. Auto-detects what is already installed and skips completed steps.

## Installation

### Step 1 — Install Claude Code (skip if already installed)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Step 2 — Add the Otoshek plugin marketplace

Open a terminal and run Claude Code in any directory, then run:

```
/plugin marketplace add otoshek/otoshek-local-setup
```

### Step 3 — Install the skill

```
/plugin install otoshek-local-setup@otoshek-otoshek-local-setup
```

That's it. The skill is now available in every Claude Code session.

> Requires Claude Code **v1.0.33 or later**. Run `claude --version` to check.

## Usage

Open a terminal in the directory where you want to clone your project, start Claude Code, then run:

```
/otoshek-local-setup git@github.com:YOUR_USERNAME/YOUR_REPO.git
```

You can also provide an HTTPS URL — the skill will convert it automatically:

```
/otoshek-local-setup https://github.com/YOUR_USERNAME/YOUR_REPO
```

Claude will guide you through the full setup, pausing only when human action is required (e.g., adding an SSH key to GitHub, providing API credentials).

## Prerequisites

The skill checks for these on startup and will tell you exactly what's missing. Install them before running the skill:

### macOS

```bash
# 1. Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Required tools
brew install git node python@3.13 mkcert
mkcert -install
```

### Linux

```bash
# 1. Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Required tools (via apt or brew)
sudo apt update && sudo apt install -y git nodejs npm
brew install python@3.13 mkcert
mkcert -install
```

### You'll also need

- A GitHub account with access to your Otoshek repository
- Your API credentials ready (Google OAuth, Mailjet, Stripe — provided during your Otoshek onboarding)
