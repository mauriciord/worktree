# Git Worktree Manager

A Git worktree manager that simplifies the creation and management of multiple working trees for the same repository.

## What is it?

Git Worktree Manager is a bash script that simplifies working with Git worktrees. It allows you to create, list, and remove worktrees intuitively, while automating common tasks such as:

- Creating branches and worktrees
- Copying configuration files (`.env`, `.cursor`, etc.)
- Copying `node_modules` to speed up development
- Automatic opening in VS Code (or Cursor with `--cursor` flag)
- Smart navigation to maintain current directory context

## How to install

### Using the install.sh script

```bash
chmod +x install.sh
./install.sh
```

The install.sh script will:

1. Download the script from the repository
2. Install it to `~/.local/bin/worktree`
3. Make the script executable
4. Check if the directory is in PATH

If `~/.local/bin` is not in your PATH, add this line to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$PATH:~/.local/bin"
```

### Manual installation

```bash
# Copy the script to a directory in PATH
cp worktree.sh ~/.local/bin/worktree
chmod +x ~/.local/bin/worktree
```

## Features

### 1. Create a new worktree

Creates a new worktree for a feature branch.

```bash
worktree add my-new-feature
```

**What it does:**

- Creates a new branch `my-new-feature` (if it doesn't exist)
- Creates a worktree at `../project-worktrees/my-new-feature`
- Copies configuration files (`.env`, `.cursor`, etc.)
- Copies `node_modules` from the current directory
- Opens in VS Code at the same relative location

### 2. Create worktree with Cursor

To open in Cursor instead of VS Code:

```bash
worktree add my-feature --cursor
```

### 3. Create worktree without copying node_modules

For large projects where you prefer to run `pnpm install` in the new worktree:

```bash
worktree add my-feature --skip-node-modules
```

### 4. List all worktrees

Shows all existing worktrees, highlighting the current one with ★:

```bash
worktree list
```

**Example output:**

```
=== Git Worktrees for my-project ===

★ [current] [main repository] → main
   Path: /Users/user/project

Worktrees:
★ [current] ▸ feature-login
     /Users/user/project-worktrees/feature-login
  ▸ feature-dashboard → dashboard-improvements
     /Users/user/project-worktrees/feature-dashboard
```

### 5. Remove a specific worktree

Removes a worktree and cleans up references:

```bash
worktree remove my-feature
```

**What it does:**

- Removes the worktree from the filesystem
- Cleans up Git references
- Forces removal even with uncommitted changes

### 6. Remove all worktrees

Removes all worktrees with confirmation:

```bash
worktree remove-all
```

**What it does:**

- Lists all worktrees that will be removed
- Asks for confirmation (y/N)
- Removes all worktrees sequentially

### 7. Help

Shows all available options:

```bash
worktree --help
# or
worktree -h
# or simply
worktree
```

## File structure

The script organizes worktrees as follows:

```
my-project/                    # Main repository
│
├── src/
├── package.json
├── .env
└── ...

my-project-worktrees/         # Worktrees directory
│
├── feature-login/             # Worktree for feature-login
│   ├── src/
│   ├── package.json
│   ├── .env                   # Copied from main
│   └── node_modules/          # Copied from main
│
└── feature-dashboard/         # Worktree for feature-dashboard
    ├── src/
    ├── package.json
    ├── .env                   # Copied from main
    └── node_modules/          # Copied from main
```

## Automatically copied files

The script automatically copies the following files and directories:

**Files:**

- `.env`

**Directories:**

- `.instrumental`
- `.agent_os`
- `.claude`
- `.cursor`
- `node_modules` (can be skipped with `--skip-node-modules`)

## Requirements

- Git
- Bash
- VS Code (optional, but recommended) or Cursor (use with `--cursor` flag)
- Operating system: macOS, Linux, or Windows with WSL

## Special features

### Copy-on-Write (COW)

On macOS with APFS, the script uses copy-on-write to copy `node_modules` more efficiently, saving space and time.

### Smart navigation

The script remembers where you were when you created the worktree and opens VS Code (or Cursor with `--cursor`) at the same relative location in the new worktree.

### Existing branch detection

If you create a worktree for a branch that already exists, the script uses the existing branch instead of creating a new one.

## Usage examples

### Feature development

```bash
# In the project directory
cd ~/projects/my-app/src/components

# Create worktree for new feature (opens in VS Code)
worktree add user-authentication

# VS Code automatically opens at:
# ~/projects/my-app-worktrees/user-authentication/src/components

# Or create worktree and open in Cursor instead
worktree add user-authentication --cursor
```

### Managing multiple features

```bash
# Create multiple features
worktree add feature-login
worktree add feature-dashboard
worktree add bugfix-header

# List all
worktree list

# Work on a specific feature
cd ~/projects/my-app-worktrees/feature-login

# Remove completed feature
worktree remove feature-login
```

### Worktree cleanup

```bash
# Remove all old worktrees
worktree remove-all

# Confirm with 'y' when prompted
```

## Usage tips

1. **Use descriptive names** for your worktrees: `feature-user-auth`, `bugfix-mobile-menu`
2. **Keep the main repository clean** by using worktrees for development
3. **Use `--skip-node-modules`** for large projects and install dependencies as needed
4. **The `list` command shows where you are** - useful when working with multiple worktrees
5. **Commit your changes** before removing worktrees to avoid losing work
