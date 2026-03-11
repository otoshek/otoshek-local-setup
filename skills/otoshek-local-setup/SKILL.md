---
name: otoshek-local-setup
description: >
  Set up a complete Otoshek local development environment from scratch.
  Installs system dependencies (Homebrew, Git, SSH, mkcert, PostgreSQL, Python 3.13, Node.js),
  configures SSL certificates, creates databases, sets up Django backend and React frontend,
  and configures Stripe integration. Use when (1) setting up a new development machine for Otoshek,
  (2) user says "set up my local environment" or "local setup",
  (3) user wants to configure their machine to develop Otoshek locally.
  Supports macOS, Linux, and Windows. Auto-detects what is already installed and skips completed steps.
  Expects a Git SSH repo URL as argument, e.g. "/otoshek-local-setup git@github.com:user/repo.git".
---

# Otoshek Local Setup

Set up a complete local development environment for the Otoshek project.

## Invocation

```
/otoshek-local-setup git@github.com:USER/REPO.git
```

The user should launch Claude from the parent directory where they want the project cloned. For example, if they run Claude from `~/Projects`, the repo will be cloned into `~/Projects/REPO/`.

## Strategy

1. Parse the repo URL from the skill arguments. If not provided, ask for it.
2. **Normalize the URL to SSH format.** The user may provide either format:
   - SSH: `git@github.com:USER/REPO.git` — use as-is
   - HTTPS: `https://github.com/USER/REPO` — convert to `git@github.com:USER/REPO.git`
   - Then check `~/.ssh/config` for a GitHub host alias (e.g., `Host github.com-work`). If an alias exists, replace `github.com` with the alias in the SSH URL (e.g., `git@github.com-work:USER/REPO.git`).
3. Derive `REPO_NAME` from the URL (last path segment without `.git`).
4. Set `PROJECT_ROOT` to `<CWD>/<REPO_NAME>` — this is the absolute path used for ALL file operations from step 3 onward.
5. Detect OS at start: run `uname -s` (Darwin = macOS, Linux = Linux). On Windows, check for `C:\Windows`.
6. For OS-specific install commands, read [references/os-commands.md](references/os-commands.md).
7. Execute steps sequentially. Check if each tool is already installed before installing. Report status as you go.
8. Pipe verbose install commands through `tail -10` to conserve context (e.g., `brew install postgresql@17 2>&1 | tail -10`). Always verify installation with a separate version check afterward.

## Claude Code Environment Constraints

Each Claude Code `Bash` tool call runs in a **fresh, non-login shell**. This has critical implications:

- **No persistent shell state** — `PATH` changes, virtual environment activations, environment variable exports, and `cd` all reset between Bash calls. You must re-establish state in every call.
- **No sudo access** — The skill does NOT install system packages requiring sudo. Step 1 checks prerequisites and stops if any are missing, providing the user with exact commands to run themselves.
- **Tool API constraints** — `AskUserQuestion` requires 2-4 options (always provide at least 2). `Write` and `Edit` tools require a `Read` first if the file may already exist.

### Shell Prefix Variables

Every Bash command that needs brew-installed tools, PostgreSQL CLI, or the Python venv must chain the relevant prefixes:

| Variable | Value (macOS) | Needed after |
|---|---|---|
| `BREW_PREFIX` | `eval "$(/opt/homebrew/bin/brew shellenv)" && ` | Step 1 |
| `PG_PATH` | `export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && ` | Step 4 |
| `VENV_ACTIVATE` | `source $PROJECT_ROOT/.venv/bin/activate && ` | Step 6 |

**Usage pattern:** `BREW_PREFIX` + `PG_PATH` + `VENV_ACTIVATE` + `<command>`

Example (Django management command):
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH" && source $PROJECT_ROOT/.venv/bin/activate && python $PROJECT_ROOT/manage.py migrate
```

**Linux note:** `BREW_PREFIX` uses `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`. `PG_PATH` is not needed on Linux (`apt` puts `psql` in the system PATH).

## Workflow

### Step 1: Prerequisites Gate

The skill does NOT install system-level dependencies (they require sudo). Instead, verify all prerequisites are present and **stop immediately** if any are missing, providing the user with exact install commands.

**macOS checks** (run each in a separate Bash call):
1. `brew --version` — Homebrew
2. `eval "$(/opt/homebrew/bin/brew shellenv)" && mkcert -version` — mkcert
3. `git --version` — Git
4. `node --version` — Node.js (v18+)
5. `eval "$(/opt/homebrew/bin/brew shellenv)" && python3.13 --version` — Python 3.13

**Linux checks:** Same tools, but use `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` for brew-installed tools (or check system PATH directly if installed via apt).

**Windows:** Check for `git`, `node`, `python`, `mkcert` on PATH. Homebrew is not used — inform user to install missing tools via Chocolatey or direct downloads.

**If any prerequisite is missing:** Print a clear list of what's missing with install commands, then **STOP**. Do not continue to Step 2. Example:
```
The following prerequisites are missing. Install them and re-run the skill:

1. Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
2. mkcert: brew install mkcert && mkcert -install
3. Python 3.13: brew install python@3.13
```

**If all present:** Set `BREW_PREFIX` for subsequent commands (`eval "$(/opt/homebrew/bin/brew shellenv)" && ` on macOS). Continue to Step 2.

### Step 2: Git + SSH + Clone Repository

**Git:** Git was already verified in the prerequisites gate (Step 1). It is guaranteed present.

**SSH for GitHub:** Test the connection directly first — this is the most reliable signal:
```bash
ssh -T git@github.com 2>&1
```
- If output contains "successfully authenticated": SSH is working. Skip key generation entirely.
- If that fails, check for existing keys and config:
  - `ls ~/.ssh/*.pub` — look for ANY public keys (users often have custom names like `id_ed25519_work`, `id_ed25519_personal`, etc.)
  - `cat ~/.ssh/config` — check for GitHub host entries (e.g., `Host github.com` or aliases like `github.com-work`)
  - If keys and config exist but `ssh -T` failed, the issue is likely agent/config, not missing keys. Debug rather than regenerate.
- Only if NO keys exist at all:
  - Ask user for their email (use AskUserQuestion with at least 2 options, e.g., "Use detected Git email" / "Enter different email")
  - Run `ssh-keygen -t ed25519 -C "user_email"`
  - Start SSH agent and add key (OS-specific commands from references/os-commands.md)
  - Copy public key to clipboard (OS-specific)

**Only if a new key was generated — PAUSE for human action:**
> I've copied your SSH public key to the clipboard. Add it to GitHub:
> 1. Go to GitHub → Settings → SSH and GPG keys
> 2. Click "New SSH key", paste, and save
> 3. Tell me when done.

After any path above, verify: `ssh -T git@github.com`

**Clone:** Run `git clone <REPO_URL>` in the current working directory. This creates `<CWD>/<REPO_NAME>/`. Set `PROJECT_ROOT` to the absolute path of this directory. Confirm by checking that `$PROJECT_ROOT/manage.py` exists.

From this point forward, ALL file paths are absolute using `$PROJECT_ROOT`:
- `$PROJECT_ROOT/backend/settings.py`
- `$PROJECT_ROOT/.vscode/launch.json`
- `$PROJECT_ROOT/frontend/vite.config.js`
- `$PROJECT_ROOT/.env.development`
- `$PROJECT_ROOT/requirements.txt`
- etc.

**VS Code:** Check `code --version`
- If found: open the project with `code $PROJECT_ROOT`
- If not found: ask the user if they want to install it (VS Code is used later for debugging with F5).
  - If yes, install (OS-specific, see references/os-commands.md), then open with `code $PROJECT_ROOT`
  - If no: skip. The user can use their preferred editor. Note that launch.json and F5 instructions later assume VS Code.

### Step 3: mkcert + SSL Certificates

mkcert was already verified in the prerequisites gate (Step 1), which also instructs the user to run `mkcert -install` (requires sudo for local CA). Do NOT attempt to run `mkcert -install` here.

**Check for existing certificates** before generating:
```bash
CERT_FILE=~/certs/localhost+2.pem
KEY_FILE=~/certs/localhost+2-key.pem
```

- If both files exist, check expiry:
  ```bash
  openssl x509 -enddate -noout -in ~/certs/localhost+2.pem
  ```
  - If not yet expired: skip generation, reuse existing certs.
  - If expired: regenerate (see below).
- If either file is missing: generate (see below).

**Generate certificates** (only if missing or expired):
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && mkdir -p ~/certs && cd ~/certs && mkcert localhost 127.0.0.1 ::1
```

Get absolute cert paths:
```bash
CERT_FILE=$(realpath ~/certs/localhost+2.pem)
KEY_FILE=$(realpath ~/certs/localhost+2-key.pem)
```

**Configure settings.json:** First **Read** `$PROJECT_ROOT/.vscode/settings.json` (it may already exist). Then create or update it to prevent Python from auto-activating the venv in integrated terminals (which breaks the frontend terminal):
```json
{
  "python.terminal.activateEnvironment": false,
  "python.terminal.activateEnvInCurrentTerminal": false
}
```

**Configure launch.json:** First **Read** `$PROJECT_ROOT/.vscode/launch.json` (it may already exist). Then create or update it. Include both backend and frontend configs, plus a compound to launch both with a single F5:
```json
{
    "version": "0.2.0",
    "configurations": [
      {
        "name": "Django_server",
        "type": "debugpy",
        "request": "launch",
        "python": "${workspaceFolder}/.venv/bin/python",
        "program": "manage.py",
        "args": [
          "runserver_plus",
          "localhost:8000",
          "--cert-file",
          "$CERT_FILE",
          "--key-file",
          "$KEY_FILE"
        ],
        "django": true,
        "justMyCode": true,
        "env": { "PYTHONUNBUFFERED": "1" },
        "cwd": "${workspaceFolder}",
        "console": "integratedTerminal"
      },
      {
        "name": "Frontend_Dev",
        "type": "pwa-node",
        "request": "launch",
        "runtimeExecutable": "npm",
        "runtimeArgs": ["run", "dev"],
        "cwd": "${workspaceFolder}/frontend",
        "console": "integratedTerminal",
        "skipFiles": ["<node_internals>/**"]
      }
    ],
    "compounds": [
      {
        "name": "Django + Frontend",
        "configurations": [
          "Django_server",
          "Frontend_Dev"
        ],
        "stopAll": true
      }
    ]
}
```
The user can select "Django + Frontend" from the debug dropdown to start both servers at once. Each opens in its own integrated terminal.

**Configure vite.config.js:** **Read** `$PROJECT_ROOT/frontend/vite.config.js` first, then **Edit** the `https` section:
```javascript
https: {
  key: fs.readFileSync(path.resolve(__dirname, '$KEY_FILE')),
  cert: fs.readFileSync(path.resolve(__dirname, '$CERT_FILE')),
},
```

### Step 4: PostgreSQL

**Check version:** `eval "$(/opt/homebrew/bin/brew shellenv)" && psql --version`
- Versions 14-17: usable, skip install. Note the major version number (e.g., 14, 17).
- Version 13 or older: recommend installing 17
- Not found: install PostgreSQL 17:
  ```bash
  eval "$(/opt/homebrew/bin/brew shellenv)" && brew install postgresql@17 2>&1 | tail -10
  ```

After install (or if already installed), define `PG_PATH` using the detected version. All subsequent `psql`, `createdb`, and `pg_isready` commands must be prefixed with both `BREW_PREFIX` and `PG_PATH`.

**Check if already running:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && pg_isready -q
```
- If ready: skip starting the service
- If not ready, start using the **installed** version (not hardcoded 17):
  ```bash
  eval "$(/opt/homebrew/bin/brew shellenv)" && brew services start postgresql@<INSTALLED_VERSION> 2>&1 | tail -5
  ```
  - Linux: `sudo systemctl start postgresql` (user must run manually)
- Verify after starting:
  ```bash
  eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && pg_isready -q
  ```

> Replace `<VERSION>` with the actual detected PostgreSQL major version throughout this step.

**Create superuser:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && createuser -s postgres 2>/dev/null || true
```

**Create a fresh database.** Never drop or modify existing databases.
Pick a unique name by checking what already exists:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && DB_NAME="local_otoshek" && while psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; do DB_NAME="local_otoshek_$((++i))"; done && createdb -U postgres -O postgres "$DB_NAME" && echo "Created database: $DB_NAME"
```
Remember the final `DB_NAME` — use it in Step 5 when configuring `settings.py`.
Tell the user which database name was created (especially if it wasn't the default).
- Verify:
  ```bash
  eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && psql -U postgres -tAc "SELECT datname FROM pg_database WHERE datname = '$DB_NAME'"
  ```

### Step 5: Configure Django Database

**Read** `$PROJECT_ROOT/backend/settings.py` first, then **Edit** the DATABASES section — use the `$DB_NAME` from Step 4:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '$DB_NAME',  # use the actual name created in Step 4
        'USER': 'postgres',
        'PASSWORD': '',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {'sslmode': 'disable'},
    }
}
```

### Step 6: Python 3.13 + Virtual Environment

Python 3.13 was already verified in the prerequisites gate (Step 1). If somehow missing, stop and ask the user to install it.

Create venv and install deps:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && python3.13 -m venv $PROJECT_ROOT/.venv
```

```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && source $PROJECT_ROOT/.venv/bin/activate && pip install -r $PROJECT_ROOT/requirements.txt 2>&1 | tail -10
```

> **From this point forward**, prepend `VENV_ACTIVATE` (`source $PROJECT_ROOT/.venv/bin/activate && `) to every Python/pip/Django command. On Windows use `$PROJECT_ROOT\.venv\Scripts\activate` instead.

### Step 7: Apply Migrations

```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && source $PROJECT_ROOT/.venv/bin/activate && python $PROJECT_ROOT/manage.py migrate
```
> Replace `<VERSION>` with the actual PostgreSQL version detected in Step 4.

### Step 8: Create Django Superuser

This step is fully automated. Create a superuser with simple credentials for local development:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && source $PROJECT_ROOT/.venv/bin/activate && python $PROJECT_ROOT/manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(username='admin', email='admin@example.com', password='admin1234')
    print('Superuser created: admin / admin1234')
else:
    print('Superuser already exists')
"
```
> Replace `<VERSION>` with the actual PostgreSQL version detected in Step 4.

Tell the user: admin panel is at https://localhost:8000/admin (credentials: `admin` / `admin1234`).

### Step 9: Configure Environment Variables

**PAUSE — Human action required:**
Ask the user to provide their credentials. They need to provide ALL of the following:
- Google OAuth Client ID and Secret
- Mailjet API keys and sender email
- Stripe Price IDs (6 values)
- Stripe test secret key (starts with `sk_test_`)

Tell the user where to find each value:
- **Google OAuth**: Google Cloud Console credentials (configured during infra setup)
- **Email**: Mailjet API credentials (configured during infra setup)
- **Stripe Price IDs**: Shown during deployment output, or in the deployment dashboard details
- **Stripe test secret key**: Stripe Dashboard → Developers → API keys → Secret key (test mode)

Create `$PROJECT_ROOT/.env.development` with their values:

```bash
# Backend and Frontend URLs
FRONTEND_URL="https://localhost:5173"
BACKEND_URL="https://localhost:8000"

# Django Superuser (local dev only)
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@example.com
DJANGO_SUPERUSER_PASSWORD=admin1234

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Email Configuration
DEFAULT_FROM_EMAIL=
MAILJET_API_URL=https://api.mailjet.com/v3.1/
MJ_APIKEY_PUBLIC=
MJ_APIKEY_PRIVATE=

# Stripe Price IDs
STRIPE_PREMIUM_MONTHLY_PRICE_ID=
STRIPE_PREMIUM_YEARLY_PRICE_ID=
STRIPE_STANDARD_MONTHLY_PRICE_ID=
STRIPE_STANDARD_YEARLY_PRICE_ID=
STRIPE_STARTER_MONTHLY_PRICE_ID=
STRIPE_STARTER_YEARLY_PRICE_ID=

# SEO — set to true when ready for search engines to index your site
# Switches robots.txt from Disallow: / to Allow: / and adds a sitemap reference
SEO_ENABLED=
```

Verify `.env.development` is listed in `$PROJECT_ROOT/.gitignore`.

### Step 10: Insert Stripe API Key and Sync Data

This step is fully automated — no human action needed.

**Insert the Stripe test key into the database** using the `sk_test_` key from step 9. The database is always fresh (created in Step 4), so insert directly without checking:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && source $PROJECT_ROOT/.venv/bin/activate && python $PROJECT_ROOT/manage.py shell -c "
from djstripe.models import APIKey
stripe_key = 'sk_test_...'  # use the actual key from step 9
is_test = 'sk_test_' in stripe_key
APIKey.objects.create(
    secret=stripe_key,
    livemode=not is_test
)
print('API key added successfully')
"
```
> Replace `<VERSION>` with the actual PostgreSQL version detected in Step 4.

**Sync Stripe data:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && export PATH="/opt/homebrew/opt/postgresql@<VERSION>/bin:$PATH" && source $PROJECT_ROOT/.venv/bin/activate && python $PROJECT_ROOT/manage.py djstripe_sync_models price plan product customer subscription WebhookEndpoint 2>&1 | tail -5
```

This pulls products, prices, plans, customers, subscriptions, and webhook endpoints from Stripe test mode into the local database.

### Step 11: Node.js + Frontend Dependencies

Node.js was already verified in the prerequisites gate (Step 1). If somehow missing, stop and ask the user to install it.

```bash
eval "$(/opt/homebrew/bin/brew shellenv)" && cd $PROJECT_ROOT/frontend && npm install
```

Create `$PROJECT_ROOT/frontend/.env.local` with the optional feature variables (commented out — uncomment when ready to use):

```bash
cat > $PROJECT_ROOT/frontend/.env.local << 'EOF'
# Analytics — Google Analytics + Microsoft Clarity via Google Tag Manager
# Get your GTM container ID from tagmanager.google.com
# Setting this activates tracking scripts and shows the cookie consent banner
# VITE_GTM_ID=GTM-XXXXXXX

# SEO — removes noindex from all pages and enables per-page titles/descriptions
# Must also set SEO_ENABLED=true in .env.development (controls robots.txt)
# VITE_SEO_ENABLED=true
EOF
```

Do NOT run `npm run dev` here — the frontend dev server is launched automatically via the "Django + Frontend" compound in launch.json (Step 3).

### Step 12: Verify

Tell the user:
> Setup complete! To start developing:
> 1. Open the project in VS Code: `code $PROJECT_ROOT`
> 2. **Important:** Select **"Django + Frontend"** from the debug dropdown (top of the Run and Debug sidebar). By default VS Code selects "Django_server" only — you must switch to the compound once. VS Code will remember your selection for subsequent launches.
> 3. Press **F5** — this launches both the Django backend and the frontend dev server in separate integrated terminals
> 4. Open https://localhost:5173 (must use `https://`, not `http://`)
> 5. You should see the application interface
> 6. Try signing in with Google OAuth and testing subscription features
