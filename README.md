# luna-repo-pull

A simple bash script to automate GitHub repository cloning and forking.

## What it does

- Checks your active GitHub account
- Clones your own repos directly
- Forks and clones other people's repos to your account
- Optionally creates a dev folder for experimentation

## Requirements

- [GitHub CLI](https://cli.github.com/) installed
- GitHub authentication configured (`gh auth login`)

If GitHub CLI is not installed, the script provides install commands for your platform:

```
brew install gh  # macOS
sudo apt install gh  # Ubuntu/Debian
winget install GitHub.cli  # Windows
```

## Usage

```bash
./luna-repo-pull.sh [repo_url]
```

**Examples:**

```bash
./luna-repo-pull.sh
./luna-repo-pull.sh https://github.com/torvalds/linux.git
```

## Configuration

Edit the variables at the top of the script:

- `create_dev_folder=true` - Set to `false` to skip creating a dev folder

## Installation

1. Download the script
2. Make it executable: `chmod +x luna-repo-pull.sh`
3. Add to your PATH or run with `./luna-repo-pull.sh`
