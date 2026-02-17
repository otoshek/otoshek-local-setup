# OS-Specific Commands Reference

Read this file to get the correct commands for the user's operating system.
Detect OS using `uname -s` (Darwin = macOS, Linux = Linux) or check `$OSTYPE`.
On Windows, detect via `systeminfo` or presence of `C:\Windows`.

## Homebrew

### macOS
```bash
# Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (zsh - default on modern macOS)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add to PATH (bash)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Linux
```bash
# Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Follow post-installation instructions printed by the script
```

### Windows
Homebrew is not available. Use Chocolatey or WSL 2 with Ubuntu (then follow Linux instructions).

## Git

### macOS
```bash
brew install git
```

### Linux
```bash
sudo apt update && sudo apt install -y git
```

### Windows
Download from https://git-scm.com/download/win. Accept default settings.

## SSH Key Generation (all platforms)
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

For multiple GitHub accounts, use custom filename:
```bash
ssh-keygen -t ed25519 -C "new-account-email@example.com" -f ~/.ssh/id_ed25519_customname
```

## SSH Agent

### macOS
```bash
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Make persistent
printf 'Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_ed25519\n' >> ~/.ssh/config
```
Fallback if `--apple-use-keychain` unavailable: `ssh-add -K ~/.ssh/id_ed25519`

### Linux
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
printf 'Host *\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/id_ed25519\n' >> ~/.ssh/config
```

### Windows (Git Bash)
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## Copy SSH Public Key

### macOS
```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

### Linux
```bash
xclip -sel clip < ~/.ssh/id_ed25519.pub
# Or: cat ~/.ssh/id_ed25519.pub  (copy manually)
```

### Windows
```bash
clip < ~/.ssh/id_ed25519.pub
```

## mkcert

### macOS
```bash
brew install mkcert
brew install nss  # optional, for Firefox
```

### Linux
```bash
sudo apt install libnss3-tools
curl -JLO https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-$(uname -s)-$(uname -m)
chmod +x mkcert-*
sudo mv mkcert-* /usr/local/bin/mkcert
```

### Windows
Download mkcert.exe from https://github.com/FiloSottile/mkcert/releases and add to PATH.

## PostgreSQL

### macOS
```bash
brew install postgresql@17

# Add to PATH (zsh)
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Add to PATH (bash)
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

# Start service
brew services start postgresql@17
```

### Linux
```bash
# Add PostgreSQL APT repository
sudo apt install -y postgresql-common
sudo sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Install
sudo apt install -y postgresql-17 postgresql-contrib-17

# Start service
sudo systemctl start postgresql
```

### Windows
Download from https://www.postgresql.org/download/

## Python 3.13

### macOS
```bash
brew install python@3.13
```

### Linux
```bash
sudo apt update
sudo apt install -y python3.13 python3.13-venv python3.13-dev
```

### Windows
Download from https://www.python.org/downloads/windows/ — enable "Add Python to PATH".

## Node.js

### macOS
```bash
brew install node
```

### Linux
```bash
sudo apt install nodejs npm
```

### Windows
Download from https://nodejs.org/en/download/

## VS Code

### macOS
```bash
brew install --cask visual-studio-code
```
After install, open VS Code and run "Shell Command: Install 'code' command in PATH" from the command palette (Cmd+Shift+P) if `code` is not found in terminal.

### Linux
```bash
sudo snap install code --classic
```
Or via apt:
```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install -y code
```

### Windows
```bash
choco install vscode
```
Or download from https://code.visualstudio.com/download
