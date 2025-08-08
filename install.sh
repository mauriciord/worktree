#!/usr/bin/env bash

# Worktree installer script
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="${SCRIPT_DIR}/worktree.sh"

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Check if worktree.sh exists in the same directory
if [[ ! -f "$SCRIPT_FILE" ]]; then
    echo "❌ Error: worktree.sh not found in the same directory as install.sh"
    echo "Please ensure both files are in the same directory"
    exit 1
fi

# Copy and install
echo "Installing worktree..."
cp "$SCRIPT_FILE" "${INSTALL_DIR}/worktree"
chmod +x "${INSTALL_DIR}/worktree"

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠️  ${INSTALL_DIR} is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "    export PATH=\"\$PATH:${INSTALL_DIR}\""
    echo ""
fi

echo "✅ Worktree installed successfully!"
echo "Run 'worktree --help' to get started"