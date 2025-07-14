#!/usr/bin/env bash
# Git Worktree Manager - A tool to manage Git worktrees with ease

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Unicode symbols
CHECK="✓"
CROSS="✗"
STAR="★"
ARROW="▸"
INFO="ℹ️"
WARNING="⚠️"

# Get git root directory
get_git_root() {
    git rev-parse --show-toplevel 2>/dev/null || {
        echo -e "${RED}${CROSS} Error: Not inside a Git repository${RESET}"
        exit 1
    }
}

# Initialize variables
PROJECT_DIR=$(get_git_root)
PROJECT_NAME=$(basename "$PROJECT_DIR")
WORKTREE_PARENT="${PROJECT_DIR}-worktrees"
CURRENT_DIR=$(pwd)
RELATIVE_PATH=""

# Calculate relative path if we're inside the project
if [[ "$CURRENT_DIR" == "$PROJECT_DIR"* ]]; then
    if [[ "$CURRENT_DIR" == "$PROJECT_DIR" ]]; then
        RELATIVE_PATH=""
    else
        RELATIVE_PATH="${CURRENT_DIR#$PROJECT_DIR/}"
    fi
fi

# Show help
show_help() {
    echo -e "${BLUE}${BOLD}=== Git Worktree Manager ===${RESET}"
    echo
    echo -e "${CYAN}Usage:${RESET} ${YELLOW}worktree <command>${RESET}"
    echo
    echo -e "${CYAN}Commands:${RESET}"
    echo -e "  ${GREEN}add <name>${RESET}          Create a new worktree for the given feature branch"
    echo -e "  ${GREEN}list${RESET}                List all worktrees"
    echo -e "  ${GREEN}remove <name>${RESET}       Remove a specific worktree"
    echo -e "  ${GREEN}remove-all${RESET}          Remove all worktrees (with confirmation)"
    echo
    echo -e "${CYAN}When creating a worktree:${RESET}"
    echo -e "  • If the branch doesn't exist, it creates a new branch"
    echo -e "  • If the branch already exists, it checks out the existing branch"
    echo -e "  • Automatically copies .env and other configuration files"
    echo -e "  • Copies node_modules from your current directory to the same location"
    echo -e "  • Opens in Cursor at the same relative path where you ran the command"
    echo
    echo -e "${CYAN}Examples:${RESET}"
    echo -e "  ${YELLOW}worktree add my-new-feature${RESET}                # Create new worktree"
    echo -e "  ${YELLOW}worktree add my-feature --skip-node-modules${RESET} # Create without copying node_modules"
    echo -e "  ${YELLOW}worktree list${RESET}                              # List all worktrees (shows current with ★)"
    echo -e "  ${YELLOW}worktree remove my-feature${RESET}                 # Remove specific worktree"
    echo -e "  ${YELLOW}worktree remove-all${RESET}                        # Remove all worktrees"
    echo
    echo -e "${CYAN}💡 Pro tip:${RESET} The 'list' command shows which worktree you're currently in with a ★ marker."
}

# Check if branch exists
branch_exists() {
    local branch_name=$1
    git show-ref --verify --quiet "refs/heads/${branch_name}" 2>/dev/null || \
    git show-ref --verify --quiet "refs/remotes/origin/${branch_name}" 2>/dev/null
}

# List worktrees
list_worktrees() {
    echo -e "${BLUE}${BOLD}=== Git Worktrees for ${PROJECT_NAME} ===${RESET}"
    echo

    local current_path=$(pwd)
    local worktrees=$(git -C "$PROJECT_DIR" worktree list)

    if [[ -z "$worktrees" ]]; then
        echo -e "${YELLOW}No worktrees found${RESET}"
        return
    fi

    # Process main repository
    while IFS= read -r line; do
        local path=$(echo "$line" | awk '{print $1}')
        local branch=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')

        if [[ "$path" == "$PROJECT_DIR" ]]; then
            local marker="  "
            if [[ "$current_path" == "$path"* ]] && [[ "$current_path" != "$WORKTREE_PARENT"* ]]; then
                marker="${CYAN}${STAR}${RESET} ${BOLD}[current]${RESET}"
            fi
            echo -e "${marker} ${BOLD}[main repository]${RESET} → ${GREEN}${branch}${RESET}"
            echo -e "     Path: ${path}"
            echo
        fi
    done <<< "$worktrees"

    # Process managed worktrees
    local has_managed=false
    while IFS= read -r line; do
        local path=$(echo "$line" | awk '{print $1}')
        local branch=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')

        if [[ "$path" == "$WORKTREE_PARENT"* ]]; then
            if [[ "$has_managed" == false ]]; then
                echo -e "${CYAN}Worktrees:${RESET}"
                has_managed=true
            fi

            local name=$(basename "$path")
            local marker="  "
            if [[ "$current_path" == "$path"* ]]; then
                marker="${CYAN}${STAR}${RESET} ${BOLD}[current]${RESET}"
            fi

            # Only show branch name if it's different from worktree name
            if [[ "$name" == "$branch" ]]; then
                echo -e "${marker} ${CYAN}${ARROW}${RESET} ${BOLD}${name}${RESET}"
            else
                echo -e "${marker} ${CYAN}${ARROW}${RESET} ${BOLD}${name}${RESET} → ${GREEN}${branch}${RESET}"
            fi
            echo -e "       ${path}"
        fi
    done <<< "$worktrees"
}

# Remove worktree
remove_worktree() {
    local name=$1

    if [[ -z "$name" ]]; then
        echo -e "${RED}${CROSS} Error: Please specify which worktree to remove${RESET}"
        echo -e "   ${YELLOW}Usage: worktree remove <worktree-name>${RESET}"
        exit 1
    fi

    local worktree_path="${WORKTREE_PARENT}/${name}"

    if [[ ! -d "$worktree_path" ]]; then
        echo -e "${RED}${CROSS} Error: Worktree '${name}' not found at ${worktree_path}${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}${BOLD}=== Removing worktree '${name}' ===${RESET}"

    if git -C "$PROJECT_DIR" worktree remove "$worktree_path" --force 2>/dev/null; then
        echo -e "${GREEN}${CHECK} Worktree '${name}' removed successfully${RESET}"
    else
        echo -e "${RED}${CROSS} Failed to remove worktree. It might have uncommitted changes.${RESET}"
        echo -e "   ${YELLOW}Use 'cd ${worktree_path}' to check and commit/stash changes.${RESET}"
        exit 1
    fi
}

# Remove all worktrees
remove_all_worktrees() {
    local worktrees=$(git -C "$PROJECT_DIR" worktree list | grep "$WORKTREE_PARENT" | awk '{print $1}')

    if [[ -z "$worktrees" ]]; then
        echo -e "${YELLOW}${INFO} No worktrees found to remove${RESET}"
        return
    fi

    echo -e "${RED}${BOLD}=== Remove All Worktrees ===${RESET}"
    echo -e "${YELLOW}${WARNING} This will remove the following worktrees:${RESET}"

    while IFS= read -r path; do
        local name=$(basename "$path")
        echo -e "  ${RED}${CROSS}${RESET} ${name}"
    done <<< "$worktrees"

    echo
    read -p "Are you sure you want to remove all worktrees? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}${CROSS} Cancelled${RESET}"
        return
    fi

    while IFS= read -r path; do
        local name=$(basename "$path")
        echo -n "Removing ${name}..."
        if git -C "$PROJECT_DIR" worktree remove "$path" --force 2>/dev/null; then
            echo -e "\r${GREEN}${CHECK} Removed ${name}${RESET}              "
        else
            echo -e "\r${YELLOW}${WARNING} Failed to remove ${name} (might have uncommitted changes)${RESET}"
        fi
    done <<< "$worktrees"

    echo
    echo -e "${GREEN}${CHECK} All worktrees removed${RESET}"
}

# Copy with copy-on-write if available (macOS APFS)
copy_with_cow() {
    local src=$1
    local dest=$2

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Try copy-on-write first
        if /bin/cp -Rc "$src" "$dest" 2>/dev/null; then
            return 0
        fi
    fi

    # Fallback to regular copy
    cp -r "$src" "$dest"
}

# Create worktree
create_worktree() {
    local feature_name=$1
    local skip_node_modules=false

    # Check for --skip-node-modules flag
    for arg in "$@"; do
        if [[ "$arg" == "--skip-node-modules" ]]; then
            skip_node_modules=true
        elif [[ "$arg" != "$1" ]]; then
            feature_name=$arg
        fi
    done

    local worktree_path="${WORKTREE_PARENT}/${feature_name}"

    if [[ -d "$worktree_path" ]]; then
        echo -e "${RED}${CROSS} Error: Worktree '${feature_name}' already exists at ${worktree_path}${RESET}"
        echo -e "   ${YELLOW}To navigate to it: cd ${worktree_path}${RESET}"
        exit 1
    fi

    echo -e "${GREEN}${BOLD}=== Creating worktree '${feature_name}' ===${RESET}"

    # Create parent directory
    mkdir -p "$WORKTREE_PARENT"

    # Check if branch exists
    if branch_exists "$feature_name"; then
        echo -e "${BLUE}🔍 Branch '${feature_name}' already exists. Creating worktree from existing branch...${RESET}"
        echo -n "Creating worktree..."
        if git -C "$PROJECT_DIR" worktree add "$worktree_path" "$feature_name" 2>/dev/null; then
            echo -e "\r${GREEN}${CHECK} Worktree created${RESET}              "
        else
            echo -e "\r${RED}${CROSS} Failed to create worktree${RESET}"
            exit 1
        fi
    else
        echo -n "Creating worktree..."
        if git -C "$PROJECT_DIR" worktree add -b "$feature_name" "$worktree_path" 2>/dev/null; then
            echo -e "\r${GREEN}${CHECK} Worktree created${RESET}              "
        else
            echo -e "\r${RED}${CROSS} Failed to create worktree${RESET}"
            exit 1
        fi
    fi

    # Copy configuration files
    copy_config_files "$worktree_path" "$skip_node_modules"

    # Open in Cursor
    open_in_cursor "$worktree_path"

    echo
    echo -e "${GREEN}${CHECK} Worktree '${feature_name}' created at:${RESET}"
    echo -e "   ${CYAN}${worktree_path}${RESET}"
    echo

    # Show navigation command
    if [[ -n "$RELATIVE_PATH" ]]; then
        echo -e "${YELLOW}To navigate to your current location in the worktree, run:${RESET}"
        echo -e "   ${BOLD}cd ${worktree_path}/${RELATIVE_PATH}${RESET}"
    else
        echo -e "${YELLOW}To navigate to your new worktree, run:${RESET}"
        echo -e "   ${BOLD}cd ${worktree_path}${RESET}"
    fi
}

# Copy configuration files
copy_config_files() {
    local worktree_path=$1
    local skip_node_modules=$2

    # Files to copy
    local files=(".env")
    local dirs=(".instrumental" ".agent_os" ".claude" ".cursor")

    # Copy files
    for file in "${files[@]}"; do
        local src="${PROJECT_DIR}/${file}"
        if [[ -f "$src" ]]; then
            echo -n "Copying ${file}..."
            cp "$src" "$worktree_path/"
            echo -e "\r${GREEN}${CHECK} Copied ${file}${RESET}              "
        fi
    done

    # Copy directories
    for dir in "${dirs[@]}"; do
        local src="${PROJECT_DIR}/${dir}"
        if [[ -d "$src" ]]; then
            echo -n "Copying ${dir}..."
            copy_with_cow "$src" "$worktree_path/${dir}"
            echo -e "\r${GREEN}${CHECK} Copied ${dir}${RESET}              "
        fi
    done

    # Copy node_modules unless skipped
    if [[ "$skip_node_modules" == true ]]; then
        echo -e "${CYAN}${INFO} Skipping node_modules copy (use 'pnpm install' in the worktree)${RESET}"
        return
    fi

    # Copy node_modules from current directory
    local node_modules_src="${CURRENT_DIR}/node_modules"

    if [[ -d "$node_modules_src" ]]; then
        local node_modules_dest
        if [[ -n "$RELATIVE_PATH" ]]; then
            local dest_dir="${worktree_path}/${RELATIVE_PATH}"
            mkdir -p "$dest_dir"
            node_modules_dest="${dest_dir}/node_modules"
        else
            node_modules_dest="${worktree_path}/node_modules"
        fi

        echo -n "Copying node_modules from current directory (this may take a while...)..."
        local start_time=$(date +%s)
        copy_with_cow "$node_modules_src" "$node_modules_dest"
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        echo -e "\r${GREEN}${CHECK} Copied node_modules (${elapsed}s)${RESET}                                          "
    else
        echo -e "${YELLOW}${WARNING} No node_modules found in current directory - you'll need to run 'pnpm install' in the worktree${RESET}"
    fi
}

# Open in Cursor
open_in_cursor() {
    local worktree_path=$1

    local path_to_open
    if [[ -n "$RELATIVE_PATH" ]]; then
        path_to_open="${worktree_path}/${RELATIVE_PATH}"
    else
        path_to_open="$worktree_path"
    fi

    echo -n "Opening in Cursor..."
    
    # Try to open in cursor with error handling
    if command -v cursor &> /dev/null && cursor "$path_to_open" 2>/dev/null; then
        echo -e "\r${GREEN}${CHECK} Opened in Cursor at ${RELATIVE_PATH:-root}${RESET}              "
    # Fallback for macOS: try using open command with Cursor
    elif [[ "$OSTYPE" == "darwin"* ]] && command -v open &> /dev/null; then
        if open -a "Cursor" "$path_to_open" 2>/dev/null; then
            echo -e "\r${GREEN}${CHECK} Opened in Cursor at ${RELATIVE_PATH:-root}${RESET}              "
        else
            echo -e "\r${YELLOW}${WARNING} Failed to open in Cursor. Please open ${path_to_open} manually.${RESET}"
        fi
    else
        echo -e "\r${YELLOW}${WARNING} Cursor not found or failed to open. Please open ${path_to_open} manually.${RESET}"
    fi
}

# Main script
main() {
    local command=$1

    if [[ -z "$command" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]]; then
        show_help
        exit 0
    fi

    case "$command" in
        add)
            if [[ -z "$2" ]]; then
                echo -e "${RED}${CROSS} Error: Please specify a name for the worktree${RESET}"
                echo -e "   ${YELLOW}Usage: worktree add <name>${RESET}"
                exit 1
            fi
            create_worktree "${@:2}"
            ;;
        list)
            list_worktrees
            ;;
        remove)
            remove_worktree "$2"
            ;;
        remove-all)
            remove_all_worktrees
            ;;
        *)
            echo -e "${RED}${CROSS} Error: Unknown command '${command}'${RESET}"
            echo -e "   ${YELLOW}Run 'worktree --help' to see available commands${RESET}"
            exit 1
            ;;
    esac
}

# Run the script
main "$@"